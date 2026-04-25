# Railway Deployment Guide for DayFi

## 🚀 Safe Database Update & Deployment Process

---

## 📋 **Pre-Deployment Checklist**

### **1. Backup Current Database**
```bash
# Create database backup before deployment
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup integrity
pg_restore --list backup_*.sql
```

### **2. Test Environment Validation**
```bash
# Run all tests locally
flutter test
flutter test integration/

# Build web version
flutter build web --release

# Test build locally
flutter run -d chrome --release
```

---

## 🗄️ **Database Migration Strategy**

### **Migration Script Creation**
Create migration files in `migrations/` directory:

```sql
-- migrations/001_add_enterprise_features.sql
-- Add new tables for enterprise features

CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    website VARCHAR(255),
    industry VARCHAR(100),
    size VARCHAR(50),
    type VARCHAR(100),
    registration_number VARCHAR(100),
    tax_id VARCHAR(100),
    logo_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    UNIQUE(organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    head_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_organizations_email ON organizations(email);
CREATE INDEX IF NOT EXISTS idx_organization_members_org_id ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_members_user_id ON organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_departments_org_id ON departments(organization_id);
```

### **Migration Runner Script**
```bash
#!/bin/bash
# migrations/run_migration.sh

set -e

echo "🚀 Starting database migration..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set"
    exit 1
fi

# Create migrations table if not exists
psql $DATABASE_URL -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# Run pending migrations
for migration_file in migrations/*.sql; do
    migration_name=$(basename "$migration_file")
    
    # Check if migration already applied
    applied=$(psql $DATABASE_URL -tAc "
        SELECT COUNT(*) FROM schema_migrations WHERE version = '$migration_name'
    ")
    
    if [ "$applied" -eq 0 ]; then
        echo "📝 Applying migration: $migration_name"
        
        # Apply migration
        psql $DATABASE_URL -f "$migration_file"
        
        # Record migration
        psql $DATABASE_URL -c "
            INSERT INTO schema_migrations (version) VALUES ('$migration_name')
        "
        
        echo "✅ Migration applied: $migration_name"
    else
        echo "⏭️  Migration already applied: $migration_name"
    fi
done

echo "🎉 Database migration completed successfully!"
```

---

## 🛤️ **Railway Deployment Setup**

### **1. Railway Configuration**
```yaml
# railway.toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "flutter build web --release && python -m http.server 8080 --directory build/web"
healthcheckPath = "/"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[[services]]
name = "dayfi-web"
source = "."
[docker]
dockerfile = "Dockerfile"
```

### **2. Dockerfile for Railway**
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Flutter web build
COPY build/web/ ./web/

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Expose port
EXPOSE 8080

# Start web server
CMD ["python", "-m", "http.server", "8080", "--directory", "web"]
```

### **3. Railway Environment Variables**
```bash
# Set in Railway dashboard
DATABASE_URL=postgresql://user:password@host:port/database
FLUTTER_ENV=production
API_BASE_URL=https://your-api.railway.app
JWT_SECRET=your-jwt-secret
WEB_APP_URL=https://your-web-app.railway.app
```

---

## 🔒 **Safe Deployment Process**

### **Step 1: Pre-Deployment**
```bash
# 1. Create backup
./scripts/backup_database.sh

# 2. Run tests
flutter test
flutter test integration/

# 3. Build locally
flutter build web --release

# 4. Test local build
python -m http.server 8080 --directory build/web &
# Open http://localhost:8080 and test
```

### **Step 2: Database Migration**
```bash
# Apply migrations safely
./migrations/run_migration.sh

# Verify migration success
psql $DATABASE_URL -c "\dt"
psql $DATABASE_URL -c "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 5;"
```

### **Step 3: Application Deployment**
```bash
# 1. Commit and push changes
git add .
git commit -m "feat: add enterprise features with database migration"
git push origin main

# 2. Railway will automatically deploy
# Monitor deployment in Railway dashboard
```

### **Step 4: Post-Deployment Verification**
```bash
# 1. Check application health
curl -f https://your-web-app.railway.app/

# 2. Test new features
# - Organization management
# - Member management
# - Department structure
# - Enhanced billing

# 3. Monitor logs
railway logs dayfi-web
```

---

## 🔄 **Rollback Plan**

### **Database Rollback**
```bash
# If migration fails, rollback
psql $DATABASE_URL -c "
DELETE FROM schema_migrations WHERE version = '001_add_enterprise_features.sql';
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS organization_members CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;
"

# Restore from backup if needed
pg_restore $DATABASE_URL < backup_20240425_120000.sql
```

### **Application Rollback**
```bash
# Revert to previous commit
git revert HEAD
git push origin main

# Railway will automatically redeploy previous version
```

---

## 📊 **Monitoring & Health Checks**

### **Health Check Endpoint**
```dart
// lib/health_check.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler healthCheckHandler() {
  return router.get('/health', (Request request) {
    return Response(200, body: 'OK');
  });
}
```

### **Database Health Check**
```dart
// lib/services/health_service.dart
Future<bool> checkDatabaseHealth() async {
  try {
    await connection.query('SELECT 1');
    return true;
  } catch (e) {
    return false;
  }
}
```

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Migration Fails**
```bash
# Check migration status
psql $DATABASE_URL -c "SELECT * FROM schema_migrations;"

# Manually fix and retry
psql $DATABASE_URL -f migrations/001_add_enterprise_features.sql
```

#### **Deployment Stuck**
```bash
# Check Railway logs
railway logs dayfi-web --follow

# Restart deployment
railway restart dayfi-web
```

#### **Database Connection Issues**
```bash
# Test connection
psql $DATABASE_URL -c "SELECT version();"

# Check connection limits
psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"
```

---

## 📈 **Performance Optimization**

### **Database Indexes**
```sql
-- Add performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_organizations_status 
ON organizations(status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_organization_members_role 
ON organization_members(role);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_departments_name 
ON departments(name);
```

### **Web Performance**
```dart
// web/index.html optimizations
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#1976D2">
<link rel="preconnect" href="https://fonts.googleapis.com">
```

---

## 🎯 **Success Criteria**

✅ **Database Migration**: Applied successfully without errors  
✅ **Application Health**: All endpoints responding correctly  
✅ **New Features**: Enterprise features working as expected  
✅ **Performance**: Page load times under 3 seconds  
✅ **Security**: No exposed sensitive data or APIs  
✅ **Monitoring**: Health checks and logging operational  

---

## 📞 **Support**

If you encounter issues during deployment:

1. **Check logs**: `railway logs dayfi-web`
2. **Verify environment**: Check Railway env variables
3. **Test locally**: Reproduce issues in local environment
4. **Rollback**: Use rollback plan if needed
5. **Contact support**: Railway support + database admin

**🎉 Your DayFi Nigerian Business Financial Command Center is ready for production deployment!**
