#!/usr/bin/env node
// Safe Migration Script for Nigeria Business Fields
// This script safely migrates existing users without data loss

import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

async function createBackup() {
  console.log('🔄 Creating backup...');
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = `backups/user_backup_${timestamp}.json`;
  
  // Ensure backups directory exists
  if (!fs.existsSync('backups')) {
    fs.mkdirSync('backups');
  }
  
  // Backup all users
  const users = await prisma.user.findMany({
    select: {
      id: true,
      email: true,
      username: true,
      isVerified: true,
      fullName: true,
      businessName: true,
      businessCategory: true,
      businessEmail: true,
      stellarPublicKey: true,
      isMerchant: true,
      createdAt: true,
    }
  });
  
  fs.writeFileSync(backupFile, JSON.stringify(users, null, 2));
  console.log(`✅ Backup created: ${backupFile}`);
  console.log(`📊 Backed up ${users.length} users`);
  
  return backupFile;
}

async function runMigration() {
  console.log('🚀 Starting safe migration...');
  
  try {
    // Step 1: Create backup
    const backupFile = await createBackup();
    
    // Step 2: Check if migration already run
    const existingUserWithAccountType = await prisma.user.findFirst({
      where: { accountType: { not: null } }
    });
    
    if (existingUserWithAccountType) {
      console.log('⚠️  Migration appears to have been run already');
      console.log('🔍 Checking for any users without accountType...');
      
      const usersWithoutAccountType = await prisma.user.count({
        where: { accountType: null }
      });
      
      if (usersWithoutAccountType === 0) {
        console.log('✅ All users already have accountType - migration complete');
        return;
      }
    }
    
    // Step 3: Run the SQL migration
    console.log('📝 Running SQL migration...');
    const migrationSQL = fs.readFileSync(
      path.join(process.cwd(), 'migrations/add_nigeria_business_fields.sql'),
      'utf8'
    );
    
    await prisma.$executeRawUnsafe(migrationSQL);
    console.log('✅ SQL migration completed');
    
    // Step 4: Verify migration
    const stats = await prisma.user.aggregate({
      _count: { id: true },
      where: { accountType: 'INDIVIDUAL' }
    });
    
    console.log(`📊 Migration Stats:`);
    console.log(`   - Total users with accountType: ${stats._count.id}`);
    console.log(`   - Backup file: ${backupFile}`);
    
    // Step 5: Test a sample user
    const sampleUser = await prisma.user.findFirst({
      where: { accountType: 'INDIVIDUAL' },
      select: {
        id: true,
        email: true,
        accountType: true,
        fullName: true,
        businessName: true,
      }
    });
    
    if (sampleUser) {
      console.log('✅ Sample user verification:');
      console.log(`   - Email: ${sampleUser.email}`);
      console.log(`   - Account Type: ${sampleUser.accountType}`);
      console.log(`   - Full Name: ${sampleUser.fullName || 'Not set'}`);
    }
    
    console.log('🎉 Migration completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    console.log('🔄 You can restore from backup if needed');
    throw error;
  }
}

async function rollbackMigration() {
  console.log('⚠️  ROLLBACK WARNING: This will remove Nigeria business fields');
  console.log('❓ Are you sure you want to continue? (yes/no)');
  
  // In a real script, you'd want to handle user input
  // For now, just show what would be rolled back
  console.log('🔄 To rollback, you would need to:');
  console.log('   1. Restore from backup file');
  console.log('   2. Or manually drop columns and types');
}

// Main execution
async function main() {
  const command = process.argv[2];
  
  switch (command) {
    case 'migrate':
      await runMigration();
      break;
    case 'backup':
      await createBackup();
      break;
    case 'rollback':
      await rollbackMigration();
      break;
    default:
      console.log('Usage:');
      console.log('  node scripts/safe-migrate.js migrate    - Run safe migration');
      console.log('  node scripts/safe-migrate.js backup     - Create backup only');
      console.log('  node scripts/safe-migrate.js rollback   - Show rollback info');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
