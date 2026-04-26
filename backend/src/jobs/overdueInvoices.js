// src/jobs/overdueInvoices.js
//
// Marks sent/viewed invoices whose dueDate has passed as "overdue".
// Runs daily at midnight server time.
//
// Wire up in src/index.js:
//
//   import { startOverdueCron } from './jobs/overdueInvoices.js';
//   startOverdueCron();
//
// Dependencies:
//   npm install node-cron

import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Marks all sent/viewed invoices with a past dueDate as overdue.
 * Safe to call manually (e.g. on boot) and via cron.
 *
 * @returns {Promise<number>} count of invoices updated
 */
export async function markOverdueInvoices() {
  const now = new Date();

  const result = await prisma.invoice.updateMany({
    where: {
      status:  { in: ['sent', 'viewed'] },
      dueDate: { lt: now },
    },
    data: {
      status:     'overdue',
      overdueAt:  now,
    },
  });

  if (result.count > 0) {
    console.log(`[overdueInvoices] Marked ${result.count} invoice(s) as overdue at ${now.toISOString()}`);
  }

  return result.count;
}

/**
 * Starts the cron schedule.
 * Call once during server startup.
 */
export function startOverdueCron() {
  // Run every day at 00:05 UTC (gives a 5 min buffer after midnight)
  cron.schedule('5 0 * * *', async () => {
    console.log('[overdueInvoices] Running overdue check…');
    try {
      await markOverdueInvoices();
    } catch (err) {
      console.error('[overdueInvoices] Error:', err.message);
    }
  });

  console.log('[overdueInvoices] Cron scheduled (daily at 00:05 UTC)');

  // Also run immediately on startup to catch anything missed during downtime
  markOverdueInvoices().catch((err) =>
    console.error('[overdueInvoices] Startup check error:', err.message),
  );
}