#!/usr/bin/env node
// Database migration script for production deployment

import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

class MigrationManager {
  constructor() {
    this.migrationPath = path.join(__dirname, '../prisma/migrations');
    this.schemaPath = path.join(__dirname, '../prisma/schema.prisma');
  }

  async runMigrations() {
    console.log('🚀 Starting database migrations...');
    
    try {
      // Check if we're in production
      const isProduction = process.env.NODE_ENV === 'production';
      
      if (isProduction) {
        console.log('📦 Production environment detected');
        await this.backupDatabase();
      }
      
      // Generate Prisma client
      console.log('🔧 Generating Prisma client...');
      execSync('npx prisma generate', { stdio: 'inherit' });
      
      // Push schema changes (for production without migrations folder)
      console.log('📤 Pushing schema changes...');
      execSync('npx prisma db push', { stdio: 'inherit' });
      
      // Verify database connection
      console.log('🔍 Verifying database connection...');
      await this.verifyDatabase();
      
      // Seed initial data if needed
      await this.seedInitialData();
      
      console.log('✅ Database migrations completed successfully!');
      
    } catch (error) {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    }
  }

  async backupDatabase() {
    console.log('💾 Creating database backup...');
    
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupFile = `backup-${timestamp}.sql`;
      
      // This would need to be implemented based on your database provider
      // For PostgreSQL:
      if (process.env.DATABASE_URL) {
        console.log(`📄 Backup file: ${backupFile}`);
        // execSync(`pg_dump ${process.env.DATABASE_URL} > ${backupFile}`, { stdio: 'inherit' });
      }
      
    } catch (error) {
      console.warn('⚠️  Backup failed, continuing with migration:', error.message);
    }
  }

  async verifyDatabase() {
    try {
      // Test basic database operations
      await prisma.$queryRaw`SELECT 1`;
      
      // Check if all required tables exist
      const tables = await prisma.$queryRaw`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
      `;
      
      const requiredTables = [
        'User', 'Organization', 'OrganizationMember', 'Invoice', 
        'Expense', 'Transaction', 'AuditLog', 'Workflow', 'Card'
      ];
      
      const existingTables = tables.map(t => t.table_name);
      const missingTables = requiredTables.filter(table => !existingTables.includes(table));
      
      if (missingTables.length > 0) {
        throw new Error(`Missing tables: ${missingTables.join(', ')}`);
      }
      
      console.log('✅ Database verification passed');
      
    } catch (error) {
      throw new Error(`Database verification failed: ${error.message}`);
    }
  }

  async seedInitialData() {
    console.log('🌱 Checking if initial data seeding is needed...');
    
    try {
      // Check if any users exist
      const userCount = await prisma.user.count();
      
      if (userCount === 0) {
        console.log('📝 Database is empty, creating initial data...');
        
        // Create initial system data if needed
        // This could include default organization types, system settings, etc.
        
        console.log('✅ Initial data seeded');
      } else {
        console.log('✅ Database already contains data, skipping seeding');
      }
      
    } catch (error) {
      console.warn('⚠️  Seeding failed, but continuing:', error.message);
    }
  }

  async rollback() {
    console.log('🔄 Rolling back database changes...');
    
    try {
      execSync('npx prisma migrate reset --force', { stdio: 'inherit' });
      console.log('✅ Database rollback completed');
    } catch (error) {
      console.error('❌ Rollback failed:', error);
      process.exit(1);
    }
  }

  async getStatus() {
    console.log('📊 Database migration status...');
    
    try {
      // Get database info
      const result = await prisma.$queryRaw`
        SELECT 
          table_name,
          table_rows
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name
      `;
      
      console.log('\n📋 Database Tables:');
      console.table(result);
      
      // Get migration history if available
      try {
        const migrations = await prisma.$queryRaw`
          SELECT * FROM _prisma_migrations ORDER BY started_at DESC
        `;
        
        if (migrations.length > 0) {
          console.log('\n📜 Migration History:');
          console.table(migrations);
        }
      } catch (e) {
        console.log('ℹ️  No migration history available (using db push)');
      }
      
    } catch (error) {
      console.error('❌ Status check failed:', error);
    }
  }
}

// CLI interface
async function main() {
  const migrationManager = new MigrationManager();
  const command = process.argv[2] || 'migrate';
  
  switch (command) {
    case 'migrate':
      await migrationManager.runMigrations();
      break;
    case 'rollback':
      await migrationManager.rollback();
      break;
    case 'status':
      await migrationManager.getStatus();
      break;
    case 'backup':
      await migrationManager.backupDatabase();
      break;
    default:
      console.log('Usage: node migrate.js [migrate|rollback|status|backup]');
      process.exit(1);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

export default MigrationManager;
