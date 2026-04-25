// src/services/monitoring.js
// Production monitoring and alerting system

import { PrismaClient } from '@prisma/client';
import { Server } from 'stellar-sdk';
import FraudDetection from './fraudDetection.js';

const prisma = new PrismaClient();

export class MonitoringService {
  constructor() {
    this.alerts = [];
    this.metrics = new Map();
    this.healthChecks = new Map();
    this.fraudDetector = new FraudDetection();
    this.lastCleanup = Date.now();
    this.maxAlerts = 50; // Limit alerts to prevent memory buildup
    
    // Initialize monitoring
    this.initializeMonitoring();
  }

  initializeMonitoring() {
    // Start periodic health checks
    this.startHealthChecks();
    
    // Start metrics collection
    this.startMetricsCollection();
    
    // Start alert monitoring
    this.startAlertMonitoring();
  }

  // Health checks
  startHealthChecks() {
    // Database health check
    this.healthChecks.set('database', {
      name: 'Database Connection',
      check: async () => {
        try {
          await prisma.$queryRaw`SELECT 1`;
          return { status: 'healthy', message: 'Database connection OK' };
        } catch (error) {
          return { status: 'unhealthy', message: `Database error: ${error.message}` };
        }
      },
      interval: 30000 // 30 seconds
    });

    // Stellar health check
    this.healthChecks.set('stellar', {
      name: 'Stellar Network',
      check: async () => {
        try {
          // Check Stellar network connectivity
          const server = new Server(process.env.STELLAR_HORIZON_URL || 'https://horizon.stellar.org');
          await server.root();
          return { status: 'healthy', message: 'Stellar network reachable' };
        } catch (error) {
          return { status: 'unhealthy', message: `Stellar error: ${error.message}` };
        }
      },
      interval: 60000 // 1 minute
    });

    // Memory usage check
    this.healthChecks.set('memory', {
      name: 'Memory Usage',
      check: async () => {
        const memUsage = process.memoryUsage();
        const totalMem = memUsage.heapTotal / 1024 / 1024; // MB
        const usedMem = memUsage.heapUsed / 1024 / 1024; // MB
        const usagePercent = (usedMem / totalMem) * 100;
        
        if (usagePercent > 90) {
          return { status: 'unhealthy', message: `Memory usage: ${usagePercent.toFixed(1)}%` };
        } else if (usagePercent > 80) {
          return { status: 'warning', message: `Memory usage: ${usagePercent.toFixed(1)}%` };
        } else {
          return { status: 'healthy', message: `Memory usage: ${usagePercent.toFixed(1)}%` };
        }
      },
      interval: 30000 // 30 seconds
    });

    // Run health checks periodically
    setInterval(() => {
      this.runHealthChecks();
    }, 30000);
  }

  async runHealthChecks() {
    const results = new Map();
    
    for (const [key, healthCheck] of this.healthChecks) {
      try {
        const result = await healthCheck.check();
        results.set(key, result);
        
        // Log health issues
        if (result.status === 'unhealthy') {
          this.createAlert({
            type: 'health_check_failed',
            severity: 'critical',
            message: `${healthCheck.name}: ${result.message}`,
            details: { check: key, result }
          });
        } else if (result.status === 'warning') {
          this.createAlert({
            type: 'health_check_warning',
            severity: 'warning',
            message: `${healthCheck.name}: ${result.message}`,
            details: { check: key, result }
          });
        }
      } catch (error) {
        results.set(key, {
          status: 'error',
          message: `Health check error: ${error.message}`
        });
      }
    }
    
    return results;
  }

  // Metrics collection
  startMetricsCollection() {
    // Collect metrics every minute
    setInterval(() => {
      this.collectMetrics();
    }, 60000);
  }

  async collectMetrics() {
    const timestamp = new Date().toISOString();
    
    // Run cleanup every 5 minutes
    if (Date.now() - this.lastCleanup > 5 * 60 * 1000) {
      this.cleanupMemory();
    }
    
    try {
      // Memory usage
      const memUsage = process.memoryUsage();
      const memoryUsagePercent = (memUsage.heapUsed / memUsage.heapTotal) * 100;
      
      // User metrics
      const totalUsers = await prisma.user.count();
      const activeUsers = await this.getActiveUsersCount(24 * 60 * 60 * 1000);
      const newUsers = await this.getNewUsersCount(24 * 60 * 60 * 1000);
      
      // Organization metrics
      const totalOrganizations = await prisma.organization.count();
      const activeOrganizations = await this.getActiveOrganizationsCount(24 * 60 * 60 * 1000);
      
      // Transaction metrics
      const totalTransactions = await prisma.transaction.count();
      const recentTransactions = await prisma.transaction.count({
        where: {
          createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
        }
      });
      
      // Financial metrics
      const totalVolume = await this.getTotalTransactionVolume(24 * 60 * 60 * 1000);
      const failedTransactions = await this.getFailedTransactionCount(24 * 60 * 60 * 1000);
      
      // Performance metrics
      const avgResponseTime = this.getAverageResponseTime();
      const errorRate = this.getErrorRate();
      
      const metrics = {
        timestamp,
        users: {
          total: totalUsers,
          active: activeUsers,
          new: newUsers
        },
        organizations: {
          total: totalOrganizations,
          active: activeOrganizations
        },
        transactions: {
          total: totalTransactions,
          recent: recentTransactions,
          volume24h: totalVolume,
          failed24h: failedTransactions
        },
        performance: {
          avgResponseTime,
          errorRate
        }
      };
      
      this.metrics.set(timestamp.toISOString(), metrics);
      
      // Keep only last 24 hours of metrics
      this.cleanupOldMetrics();
      
      // Check for anomalies
      await this.checkMetricAnomalies(metrics);
      
    } catch (error) {
      console.error('Error collecting metrics:', error);
    }
  }

  async getActiveUsersCount(timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    return await prisma.user.count({
      where: {
        lastLoginAt: { gte: cutoff }
      }
    });
  }

  async getNewUsersCount(timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    return await prisma.user.count({
      where: {
        createdAt: { gte: cutoff }
      }
    });
  }

  async getActiveOrganizationsCount(timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const organizations = await prisma.organization.findMany({
      include: {
        members: {
          include: {
            user: {
              select: { lastLoginAt: true }
            }
          }
        }
      }
    });
    
    return organizations.filter(org => 
      org.members.some(member => 
        member.user.lastLoginAt && member.user.lastLoginAt >= cutoff
      )
    ).length;
  }

  async getTotalTransactionVolume(timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const result = await prisma.transaction.aggregate({
      where: {
        createdAt: { gte: cutoff },
        status: 'confirmed'
      },
      _sum: { amount: true }
    });
    
    return result._sum.amount || 0;
  }

  async getFailedTransactionCount(timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    return await prisma.transaction.count({
      where: {
        createdAt: { gte: cutoff },
        status: 'failed'
      }
    });
  }

  getAverageResponseTime() {
    // This would be calculated from request timing data
    // For now, return a placeholder
    return 150; // milliseconds
  }

  getErrorRate() {
    // This would be calculated from request logs
    // For now, return a placeholder
    return 0.02; // 2%
  }

  cleanupOldMetrics() {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    for (const [timestamp] of this.metrics) {
      if (new Date(timestamp) < cutoff) {
        this.metrics.delete(timestamp);
      }
    }
  }

  // Alert monitoring
  startAlertMonitoring() {
    // Check for alerts every 30 seconds
    setInterval(() => {
      this.monitorAlerts();
    }, 30000);
  }

  async monitorAlerts() {
    // Check for metric anomalies
    const recentMetrics = Array.from(this.metrics.values()).slice(-10);
    
    if (recentMetrics.length < 5) return;
    
    // Check error rate
    const avgErrorRate = recentMetrics.reduce((sum, m) => sum + m.performance.errorRate, 0) / recentMetrics.length;
    if (avgErrorRate > 0.05) { // 5% error rate threshold
      this.createAlert({
        type: 'high_error_rate',
        severity: 'warning',
        message: `High error rate detected: ${(avgErrorRate * 100).toFixed(2)}%`,
        details: { avgErrorRate }
      });
    }
    
    // Check failed transactions
    const avgFailedTransactions = recentMetrics.reduce((sum, m) => sum + m.transactions.failed24h, 0) / recentMetrics.length;
    if (avgFailedTransactions > 10) {
      this.createAlert({
        type: 'high_failed_transactions',
        severity: 'warning',
        message: `High failed transaction rate: ${avgFailedTransactions.toFixed(0)} in 24h`,
        details: { avgFailedTransactions }
      });
    }
  }

  async checkMetricAnomalies(metrics) {
    // Check for unusual patterns in metrics
    const previousMetrics = Array.from(this.metrics.values()).slice(-2, -1);
    
    if (previousMetrics.length === 0) return;
    
    const prev = previousMetrics[0];
    
    // Check for sudden drops in active users
    if (metrics.users.active < prev.users.active * 0.5) {
      this.createAlert({
        type: 'user_activity_drop',
        severity: 'warning',
        message: `Significant drop in active users: ${metrics.users.active} vs ${prev.users.active}`,
        details: { current: metrics.users.active, previous: prev.users.active }
      });
    }
    
    // Check for unusual transaction volume spikes
    if (metrics.transactions.volume24h > prev.transactions.volume24h * 5) {
      this.createAlert({
        type: 'transaction_volume_spike',
        severity: 'info',
        message: `Transaction volume spike detected`,
        details: { current: metrics.transactions.volume24h, previous: prev.transactions.volume24h }
      });
    }
  }

  // Alert management
  createAlert(alert) {
    const alertWithTimestamp = {
      ...alert,
      id: Date.now().toString(),
      timestamp: new Date(),
      acknowledged: false
    };
    
    this.alerts.push(alertWithTimestamp);
    
    // Keep only last 100 alerts
    if (this.alerts.length > 100) {
      this.alerts = this.alerts.slice(-100);
    }
    
    // Log critical alerts
    if (alert.severity === 'critical') {
      console.error('CRITICAL ALERT:', alert);
      // Could send to external monitoring service
    }
    
    return alertWithTimestamp;
  }

  acknowledgeAlert(alertId) {
    const alert = this.alerts.find(a => a.id === alertId);
    if (alert) {
      alert.acknowledged = true;
      alert.acknowledgedAt = new Date();
    }
  }

  // API endpoints for monitoring
  async getHealthStatus() {
    const results = await this.runHealthChecks();
    const overallStatus = Array.from(results.values()).every(r => r.status === 'healthy') ? 'healthy' : 'unhealthy';
    
    return {
      status: overallStatus,
      timestamp: new Date(),
      checks: Object.fromEntries(results)
    };
  }

  getMetrics(timeWindow = 60 * 60 * 1000) { // Default 1 hour
    const cutoff = new Date(Date.now() - timeWindow);
    
    const filteredMetrics = Array.from(this.metrics.entries())
      .filter(([timestamp]) => new Date(timestamp) >= cutoff)
      .map(([timestamp, metrics]) => ({ timestamp, ...metrics }));
    
    return filteredMetrics;
  }

  getAlerts(severity = null, acknowledged = null) {
    let filteredAlerts = this.alerts;
    
    if (severity) {
      filteredAlerts = filteredAlerts.filter(a => a.severity === severity);
    }
    
    if (acknowledged !== null) {
      filteredAlerts = filteredAlerts.filter(a => a.acknowledged === acknowledged);
    }
    
    return filteredAlerts.sort((a, b) => b.timestamp - a.timestamp);
  }

  // Memory cleanup to prevent memory buildup
  cleanupMemory() {
    const now = Date.now();
    
    // Clean up old alerts (keep only last 50)
    if (this.alerts.length > this.maxAlerts) {
      this.alerts = this.alerts
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, this.maxAlerts);
    }
    
    // Clean up old metrics (keep only last 24 hours)
    const metricsCutoff = now - (24 * 60 * 60 * 1000);
    for (const [timestamp] of this.metrics.entries()) {
      if (new Date(timestamp).getTime() < metricsCutoff) {
        this.metrics.delete(timestamp);
      }
    }
    
    this.lastCleanup = now;
  }

  async getSystemOverview() {
    const health = await this.getHealthStatus();
    const metrics = this.getMetrics();
    const alerts = this.getAlerts();
    const fraudStats = await this.fraudDetector.getFraudStats();
    
    return {
      health,
      metrics: metrics.slice(-1)[0] || null,
      alerts: {
        total: alerts.length,
        critical: alerts.filter(a => a.severity === 'critical').length,
        warning: alerts.filter(a => a.severity === 'warning').length,
        info: alerts.filter(a => a.severity === 'info').length,
        unacknowledged: alerts.filter(a => !a.acknowledged).length
      },
      fraud: fraudStats,
      timestamp: new Date()
    };
  }
}

export default MonitoringService;
