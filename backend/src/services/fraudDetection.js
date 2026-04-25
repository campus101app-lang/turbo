// src/services/fraudDetection.js
// Advanced fraud detection and monitoring system

import { PrismaClient } from '@prisma/client';
import AuditLog from '../models/AuditLog.js';

const prisma = new PrismaClient();

export class FraudDetection {
  constructor() {
    this.suspiciousPatterns = new Map();
    this.userRiskScores = new Map();
    this.organizationRiskScores = new Map();
    
    // Initialize fraud detection rules
    this.initializeRules();
  }

  initializeRules() {
    // Define suspicious patterns and their risk scores
    this.suspiciousPatterns.set('rapid_transactions', {
      threshold: 10, // transactions in 5 minutes
      windowMs: 5 * 60 * 1000,
      riskScore: 30,
      description: 'Unusually high transaction frequency'
    });

    this.suspiciousPatterns.set('large_amount', {
      threshold: 10000, // $10,000 USDC
      riskScore: 25,
      description: 'Unusually large transaction amount'
    });

    this.suspiciousPatterns.set('multiple_failed_logins', {
      threshold: 5, // failed logins
      windowMs: 15 * 60 * 1000,
      riskScore: 40,
      description: 'Multiple failed authentication attempts'
    });

    this.suspiciousPatterns.set('suspicious_ip_changes', {
      threshold: 3, // different IPs in short time
      windowMs: 30 * 60 * 1000,
      riskScore: 20,
      description: 'Rapid IP address changes'
    });

    this.suspiciousPatterns.set('unusual_device_changes', {
      threshold: 2, // different user agents
      windowMs: 60 * 60 * 1000,
      riskScore: 15,
      description: 'Unusual device or browser changes'
    });

    this.suspiciousPatterns.set('invoice_approval_anomaly', {
      threshold: 5, // self-approvals
      windowMs: 24 * 60 * 60 * 1000,
      riskScore: 50,
      description: 'Potential self-approval of invoices'
    });

    this.suspiciousPatterns.set('expense_pattern_anomaly', {
      threshold: 20, // expenses submitted
      windowMs: 60 * 60 * 1000,
      riskScore: 35,
      description: 'Unusually high expense submission rate'
    });
  }

  // Analyze transaction for fraud indicators
  async analyzeTransaction(transaction, userId, organizationId) {
    const riskFactors = [];
    let totalRiskScore = 0;

    // Check amount threshold
    if (transaction.amount > this.suspiciousPatterns.get('large_amount').threshold) {
      riskFactors.push({
        type: 'large_amount',
        score: this.suspiciousPatterns.get('large_amount').riskScore,
        details: { amount: transaction.amount }
      });
      totalRiskScore += this.suspiciousPatterns.get('large_amount').riskScore;
    }

    // Check rapid transaction pattern
    const recentTransactions = await this.getRecentTransactions(userId, 5 * 60 * 1000);
    if (recentTransactions.length >= this.suspiciousPatterns.get('rapid_transactions').threshold) {
      riskFactors.push({
        type: 'rapid_transactions',
        score: this.suspiciousPatterns.get('rapid_transactions').riskScore,
        details: { count: recentTransactions.length }
      });
      totalRiskScore += this.suspiciousPatterns.get('rapid_transactions').riskScore;
    }

    // Check for unusual patterns
    const unusualPatterns = await this.detectUnusualPatterns(userId, organizationId);
    riskFactors.push(...unusualPatterns);
    totalRiskScore += unusualPatterns.reduce((sum, p) => sum + p.score, 0);

    // Update user risk score
    this.updateUserRiskScore(userId, totalRiskScore);

    // Log fraud analysis
    await this.logFraudAnalysis(userId, organizationId, 'transaction_analysis', {
      transactionId: transaction.id,
      riskFactors,
      totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore)
    });

    return {
      riskScore: totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore),
      riskFactors,
      shouldBlock: totalRiskScore >= 80, // Block high-risk transactions
      shouldReview: totalRiskScore >= 50, // Flag for manual review
    };
  }

  // Analyze authentication attempts
  async analyzeAuthAttempt(userId, ipAddress, userAgent, success) {
    const riskFactors = [];
    let totalRiskScore = 0;

    // Check for multiple failed attempts
    const recentFailedAttempts = await this.getRecentAuthAttempts(userId, false, 15 * 60 * 1000);
    if (recentFailedAttempts.length >= this.suspiciousPatterns.get('multiple_failed_logins').threshold) {
      riskFactors.push({
        type: 'multiple_failed_logins',
        score: this.suspiciousPatterns.get('multiple_failed_logins').riskScore,
        details: { failedAttempts: recentFailedAttempts.length }
      });
      totalRiskScore += this.suspiciousPatterns.get('multiple_failed_logins').riskScore;
    }

    // Check for IP changes
    const recentIPs = await this.getRecentIPs(userId, 30 * 60 * 1000);
    if (recentIPs.length >= this.suspiciousPatterns.get('suspicious_ip_changes').threshold) {
      riskFactors.push({
        type: 'suspicious_ip_changes',
        score: this.suspiciousPatterns.get('suspicious_ip_changes').riskScore,
        details: { uniqueIPs: recentIPs.length }
      });
      totalRiskScore += this.suspiciousPatterns.get('suspicious_ip_changes').riskScore;
    }

    // Check for device changes
    const recentDevices = await this.getRecentDevices(userId, 60 * 60 * 1000);
    if (recentDevices.length >= this.suspiciousPatterns.get('unusual_device_changes').threshold) {
      riskFactors.push({
        type: 'unusual_device_changes',
        score: this.suspiciousPatterns.get('unusual_device_changes').riskScore,
        details: { uniqueDevices: recentDevices.length }
      });
      totalRiskScore += this.suspiciousPatterns.get('unusual_device_changes').riskScore;
    }

    // Update user risk score
    this.updateUserRiskScore(userId, totalRiskScore);

    // Log analysis
    await this.logFraudAnalysis(userId, null, 'auth_analysis', {
      success,
      ipAddress,
      riskFactors,
      totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore)
    });

    return {
      riskScore: totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore),
      riskFactors,
      shouldBlock: !success && totalRiskScore >= 60, // Block suspicious failed attempts
      requiresAdditionalAuth: totalRiskScore >= 40,
    };
  }

  // Analyze invoice approval patterns
  async analyzeInvoiceApproval(invoiceId, approverId, organizationId) {
    const riskFactors = [];
    let totalRiskScore = 0;

    // Check for self-approvals
    const invoice = await prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: { user: true }
    });

    if (invoice && invoice.userId === approverId) {
      riskFactors.push({
        type: 'self_approval',
        score: 50,
        details: { invoiceId, approverId, creatorId: invoice.userId }
      });
      totalRiskScore += 50;
    }

    // Check approval frequency
    const recentApprovals = await this.getRecentApprovals(approverId, 24 * 60 * 60 * 1000);
    if (recentApprovals.length >= this.suspiciousPatterns.get('invoice_approval_anomaly').threshold) {
      riskFactors.push({
        type: 'high_approval_frequency',
        score: this.suspiciousPatterns.get('invoice_approval_anomaly').riskScore,
        details: { approvalCount: recentApprovals.length }
      });
      totalRiskScore += this.suspiciousPatterns.get('invoice_approval_anomaly').riskScore;
    }

    // Log analysis
    await this.logFraudAnalysis(approverId, organizationId, 'invoice_approval_analysis', {
      invoiceId,
      riskFactors,
      totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore)
    });

    return {
      riskScore: totalRiskScore,
      riskLevel: this.getRiskLevel(totalRiskScore),
      riskFactors,
      shouldBlock: totalRiskScore >= 80,
      requiresReview: totalRiskScore >= 50,
    };
  }

  // Get risk level based on score
  getRiskLevel(score) {
    if (score >= 80) return 'CRITICAL';
    if (score >= 60) return 'HIGH';
    if (score >= 40) return 'MEDIUM';
    if (score >= 20) return 'LOW';
    return 'MINIMAL';
  }

  // Update user risk score
  updateUserRiskScore(userId, additionalScore) {
    const currentScore = this.userRiskScores.get(userId) || 0;
    const newScore = Math.max(0, Math.min(100, currentScore + additionalScore));
    this.userRiskScores.set(userId, newScore);
    
    // Decay risk score over time
    setTimeout(() => {
      const decayedScore = Math.max(0, newScore - 5);
      this.userRiskScores.set(userId, decayedScore);
    }, 60 * 60 * 1000); // Decay after 1 hour
  }

  // Get recent transactions for pattern analysis
  async getRecentTransactions(userId, timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        createdAt: { gte: cutoff }
      },
      select: { id: true, amount: true, createdAt: true }
    });

    return transactions;
  }

  // Get recent auth attempts
  async getRecentAuthAttempts(userId, success, timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const logs = await prisma.auditLog.findMany({
      where: {
        userId,
        action: { startsWith: 'auth_' },
        timestamp: { gte: cutoff },
        details: {
          path: [],
          string_contains: success ? 'login' : 'login_failed'
        }
      },
      select: { id: true, timestamp: true }
    });

    return logs;
  }

  // Get recent IP addresses
  async getRecentIPs(userId, timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const logs = await prisma.auditLog.findMany({
      where: {
        userId,
        timestamp: { gte: cutoff },
        ipAddress: { not: null }
      },
      select: { ipAddress: true }
    });

    const uniqueIPs = [...new Set(logs.map(log => log.ipAddress))];
    return uniqueIPs;
  }

  // Get recent devices
  async getRecentDevices(userId, timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const logs = await prisma.auditLog.findMany({
      where: {
        userId,
        timestamp: { gte: cutoff },
        userAgent: { not: null }
      },
      select: { userAgent: true }
    });

    const uniqueDevices = [...new Set(logs.map(log => log.userAgent))];
    return uniqueDevices;
  }

  // Get recent approvals
  async getRecentApprovals(userId, timeWindow) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const logs = await prisma.auditLog.findMany({
      where: {
        userId,
        action: 'invoice_approved',
        timestamp: { gte: cutoff }
      },
      select: { id: true, timestamp: true }
    });

    return logs;
  }

  // Detect unusual patterns
  async detectUnusualPatterns(userId, organizationId) {
    const patterns = [];
    
    // This could be expanded with ML-based anomaly detection
    // For now, implement basic rule-based detection
    
    return patterns;
  }

  // Log fraud analysis
  async logFraudAnalysis(userId, organizationId, analysisType, details) {
    await AuditLog.log({
      userId,
      organizationId,
      action: `fraud_${analysisType}`,
      resourceType: 'fraud_analysis',
      resourceId: null,
      details: {
        analysisType,
        ...details,
        timestamp: new Date().toISOString()
      },
      ipAddress: null,
      userAgent: null,
    });
  }

  // Get fraud statistics for monitoring
  async getFraudStats(timeWindow = 24 * 60 * 60 * 1000) {
    const cutoff = new Date(Date.now() - timeWindow);
    
    const fraudLogs = await prisma.auditLog.findMany({
      where: {
        action: { startsWith: 'fraud_' },
        timestamp: { gte: cutoff }
      },
      select: {
        action: true,
        details: true,
        timestamp: true,
        userId: true,
        organizationId: true
      }
    });

    const stats = {
      totalAnalyses: fraudLogs.length,
      riskLevelDistribution: {
        CRITICAL: 0,
        HIGH: 0,
        MEDIUM: 0,
        LOW: 0,
        MINIMAL: 0
      },
      analysisTypes: {},
      timeWindow,
      highRiskUsers: [],
      highRiskOrganizations: []
    };

    fraudLogs.forEach(log => {
      const details = log.details || {};
      const riskLevel = details.riskLevel || 'MINIMAL';
      const analysisType = details.analysisType || 'unknown';
      
      stats.riskLevelDistribution[riskLevel]++;
      stats.analysisTypes[analysisType] = (stats.analysisTypes[analysisType] || 0) + 1;
      
      if (details.totalRiskScore >= 60) {
        stats.highRiskUsers.push(log.userId);
      }
      
      if (log.organizationId && details.totalRiskScore >= 60) {
        stats.highRiskOrganizations.push(log.organizationId);
      }
    });

    return stats;
  }

  // Block suspicious activity
  async blockSuspiciousActivity(userId, reason, duration = 60 * 60 * 1000) {
    // This could integrate with a user blocking system
    console.log(`Blocking user ${userId} for ${duration}ms due to: ${reason}`);
    
    // Log the blocking action
    await AuditLog.log({
      userId,
      action: 'fraud_user_blocked',
      resourceType: 'user',
      resourceId: userId,
      details: { reason, duration, blockedAt: new Date() },
      ipAddress: null,
      userAgent: null,
    });
  }
}

export default FraudDetection;
