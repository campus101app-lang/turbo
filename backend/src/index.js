// src/index.js
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import authRoutes        from './routes/auth.js';
import walletRoutes      from './routes/wallet.js';
import userRoutes        from './routes/user.js';
import transactionRoutes from './routes/transactions.js';
import sep10Routes       from './routes/sep10.js';
import sep24Routes       from './routes/sep24.js';
import sep38Routes       from './routes/sep38.js';
import tomlRoutes        from './routes/toml.js';
import inventoryRoutes   from './routes/inventory.js';
import paymentsRoutes    from './routes/payments.js';
import invoicesRoutes    from './routes/invoices.js';
import expensesRoutes    from './routes/expenses.js';
import cardsRoutes       from './routes/cards.js';
import workflowsRoutes   from './routes/workflows.js';
import requestsRoutes    from './routes/requests.js';
import businessAuthRoutes from './routes/businessAuth.js';
import organizationRoutes from './routes/organization.js';
import billingRoutes      from './routes/billing.js';
import shopRoutes         from './routes/shop.js';
import { errorHandler }  from './middleware/errorHandler.js';
import { attachRequestContext } from './middleware/requestContext.js';
import { auditLogger, addRequestStartTime } from './middleware/auditLogger.js';
import organizationRateLimit from './middleware/organizationRateLimit.js';
import MonitoringService from './services/monitoring.js';
import FraudDetection from './services/fraudDetection.js';
import { sendError }     from './utils/http.js';
import { authenticate, requirePermission } from './middleware/auth.js';

dotenv.config();

const app     = express();
app.set('trust proxy', 1);
const PORT    = process.env.PORT || 3001;
const NETWORK = process.env.STELLAR_NETWORK || 'mainnet';

// ─── Initialize Services ───────────────────────────────────────────────────────

const monitoringService = new MonitoringService();
const fraudDetection = new FraudDetection();

// Make services available globally
global.monitoringService = monitoringService;
global.fraudDetection = fraudDetection;

// ─── Middleware ───────────────────────────────────────────────────────────────

const corsOptions = {
  origin: [
    process.env.FRONTEND_URL || 'https://dayfi.me',
    'http://localhost:3000',
    'http://localhost:5173',
    /^http:\/\/localhost:\d+$/,
    /\.dayfi\.me$/,
  ],
  credentials: true,
};

app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(attachRequestContext);
app.use(addRequestStartTime);
app.use(auditLogger({ 
  enabled: true,
  skipActions: ['health_check', 'get_health'],
  logUnauthenticated: false 
}));
app.use(organizationRateLimit());

const globalLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 300 });
const authLimiter   = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    code: 'RATE_LIMITED',
    message: 'Too many auth attempts, try again later.',
    details: null,
  },
});
const sep10Limiter  = rateLimit({ windowMs: 60 * 1000, max: 30 });

app.use(globalLimiter);
app.use(attachRequestContext);
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── SEP-01: stellar.toml ─────────────────────────────────────────────────────

app.use('/.well-known', tomlRoutes);

// ─── Health ───────────────────────────────────────────────────────────────────

app.get('/health', (_, res) => res.json({
  status:    'ok',
  service:   'dayfi-backend',
  version:   '1.0.0',
  network:   NETWORK,
  timestamp: new Date().toISOString(),
}));

// ─── API Routes ───────────────────────────────────────────────────────────

app.use('/api/auth', authRoutes);
app.use('/auth', businessAuthRoutes);
app.use('/api/organization', organizationRoutes);
app.use('/api/user',         userRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/inventory',    inventoryRoutes);
app.use('/api/payments',     paymentsRoutes);
app.use('/api/invoices',     invoicesRoutes);
app.use('/api/expenses',     expensesRoutes);
app.use('/api/cards',        cardsRoutes);
app.use('/api/workflows',    workflowsRoutes);
app.use('/api/requests',     requestsRoutes);
app.use('/api/billing',      billingRoutes);
app.use('/api/shop',         shopRoutes);

// ─── SEP Routes ───────────────────────────────────────────────────────────────

app.use('/sep10', sep10Limiter, sep10Routes);
app.use('/sep24', sep24Routes);
app.use('/sep38', sep38Routes);

// ─── Monitoring Endpoints ─────────────────────────────────────────────────────

app.get('/health', async (req, res) => {
  try {
    const health = await monitoringService.getHealthStatus();
    res.json(health);
  } catch (err) {
    res.status(500).json({ status: 'unhealthy', error: err.message });
  }
});

app.get('/monitoring/metrics', authenticate, requirePermission('view_reports'), async (req, res) => {
  try {
    const timeWindow = parseInt(req.query.window) || 60 * 60 * 1000; // Default 1 hour
    const metrics = monitoringService.getMetrics(timeWindow);
    res.json({ metrics });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

app.get('/monitoring/alerts', authenticate, requirePermission('view_reports'), async (req, res) => {
  try {
    const severity = req.query.severity;
    const acknowledged = req.query.acknowledged === 'true' ? true : req.query.acknowledged === 'false' ? false : null;
    const alerts = monitoringService.getAlerts(severity, acknowledged);
    res.json({ alerts });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

app.post('/monitoring/alerts/:alertId/acknowledge', authenticate, requirePermission('manage_settings'), async (req, res) => {
  try {
    monitoringService.acknowledgeAlert(req.params.alertId);
    res.json({ success: true });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

app.get('/monitoring/overview', authenticate, requirePermission('view_reports'), async (req, res) => {
  try {
    const overview = await monitoringService.getSystemOverview();
    res.json(overview);
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

app.get('/fraud/stats', authenticate, requirePermission('view_reports'), async (req, res) => {
  try {
    const timeWindow = parseInt(req.query.window) || 24 * 60 * 60 * 1000; // Default 24 hours
    const stats = await fraudDetection.getFraudStats(timeWindow);
    res.json({ stats });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── Public Username Resolution ───────────────────────────────────────────────

app.get('/resolve/:username', async (req, res) => {
  const { resolveUsername } = await import('./services/walletService.js');
  try {
    const result = await resolveUsername(req.params.username);
    if (!result) return sendError(res, 404, 'NOT_FOUND', 'Username not found.');
    res.json(result);
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

app.use((req, res) => {
  sendError(res, 404, 'NOT_FOUND', 'Route not found.');
});

app.use(errorHandler);

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`
  ╔════════════════════════════════════════╗
  ║          DAYFI BACKEND v1.0            ║
  ║  Mode    : PRODUCTION                  ║
  ║  Port    : ${PORT.toString().padEnd(28)}║
  ║  Network : ${NETWORK.toUpperCase().padEnd(28)}║
  ║  Status  : LIVE & MONITORING           ║
  ╚════════════════════════════════════════╝
  `);
  });
}

export default app;