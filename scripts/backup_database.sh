#!/bin/bash

# Database Backup Script for DayFi
# Creates timestamped backups before deployment

set -e

echo "💾 Creating database backup..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set"
    echo "Please set DATABASE_URL environment variable"
    exit 1
fi

# Create backup directory if not exists
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Create backup
echo "📦 Creating backup: $BACKUP_FILE"
if pg_dump "$DATABASE_URL" > "$BACKUP_FILE"; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    
    # Compress backup
    echo "🗜️  Compressing backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
    
    echo "✅ Backup compressed: $BACKUP_FILE"
    
    # Show backup size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "📊 Backup size: $BACKUP_SIZE"
    
    # Clean old backups (keep last 5)
    echo "🧹 Cleaning old backups..."
    cd "$BACKUP_DIR"
    ls -t backup_*.sql.gz | tail -n +6 | xargs -r rm
    cd ..
    
    echo "✅ Old backups cleaned up"
    
else
    echo "❌ Failed to create backup"
    exit 1
fi

echo ""
echo "🎉 Database backup completed successfully!"
echo "📁 Backup location: $BACKUP_FILE"

# Verify backup integrity
echo ""
echo "🔍 Verifying backup integrity..."
if gunzip -t "$BACKUP_FILE" 2>/dev/null; then
    echo "✅ Backup integrity verified"
else
    echo "❌ Backup integrity check failed"
    exit 1
fi
