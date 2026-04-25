#!/bin/bash

# Database Migration Runner for DayFi
# Safely applies database migrations with rollback capability

set -e

echo "🚀 Starting database migration..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set"
    echo "Please set DATABASE_URL environment variable"
    exit 1
fi

# Function to check if migration exists
migration_exists() {
    local migration_name=$1
    local count=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM schema_migrations WHERE version = '$migration_name'")
    echo $count
}

# Function to apply migration
apply_migration() {
    local migration_file=$1
    local migration_name=$(basename "$migration_file")
    
    echo "📝 Applying migration: $migration_name"
    
    # Start transaction
    psql "$DATABASE_URL" -c "BEGIN;" || {
        echo "❌ Failed to start transaction"
        exit 1
    }
    
    # Apply migration
    if psql "$DATABASE_URL" -f "$migration_file"; then
        # Record migration
        psql "$DATABASE_URL" -c "INSERT INTO schema_migrations (version) VALUES ('$migration_name');" || {
            echo "❌ Failed to record migration"
            psql "$DATABASE_URL" -c "ROLLBACK;"
            exit 1
        }
        
        # Commit transaction
        psql "$DATABASE_URL" -c "COMMIT;" || {
            echo "❌ Failed to commit transaction"
            exit 1
        }
        
        echo "✅ Migration applied: $migration_name"
    else
        echo "❌ Failed to apply migration: $migration_name"
        psql "$DATABASE_URL" -c "ROLLBACK;"
        exit 1
    fi
}

# Create migrations table if not exists
echo "🔧 Setting up migrations table..."
psql "$DATABASE_URL" -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
" || {
    echo "❌ Failed to create migrations table"
    exit 1
}

# Check if migrations directory exists
if [ ! -d "migrations" ]; then
    echo "❌ Migrations directory not found"
    exit 1
fi

# Get all migration files sorted by name
migration_files=$(find migrations -name "*.sql" -type f | sort)

if [ -z "$migration_files" ]; then
    echo "⚠️  No migration files found"
    exit 0
fi

# Run pending migrations
for migration_file in $migration_files; do
    migration_name=$(basename "$migration_file")
    
    # Check if migration already applied
    applied_count=$(migration_exists "$migration_name")
    
    if [ "$applied_count" -eq 0 ]; then
        apply_migration "$migration_file"
    else
        echo "⏭️  Migration already applied: $migration_name"
    fi
done

echo ""
echo "🎉 Database migration completed successfully!"
echo ""
echo "📊 Applied migrations:"
psql "$DATABASE_URL" -c "SELECT version, applied_at FROM schema_migrations ORDER BY applied_at;"
