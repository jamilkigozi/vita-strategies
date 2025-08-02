#!/bin/bash

# =============================================================================
# VITA STRATEGIES - DATA BACKUP SCRIPT
# =============================================================================
# Backup all critical data to GCS buckets
# =============================================================================

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S UTC")
ENVIRONMENT="${1:-production}"

echo "💾 VITA STRATEGIES DATA BACKUP"
echo "==============================="
echo "📅 Backup Time: $BACKUP_DATE"
echo "🏷️  Environment: $ENVIRONMENT"
echo ""

# Load environment variables
if [[ -f "environments/$ENVIRONMENT/.env" ]]; then
    source "environments/$ENVIRONMENT/.env"
    echo "✅ Loaded $ENVIRONMENT environment"
else
    echo "❌ Environment file not found: environments/$ENVIRONMENT/.env"
    exit 1
fi

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================

BACKUP_BUCKET="vita-strategies-data-backup-$ENVIRONMENT"
ERPNEXT_BUCKET="vita-strategies-erpnext-$ENVIRONMENT"
ANALYTICS_BUCKET="vita-strategies-analytics-$ENVIRONMENT"

BACKUP_DIR="/tmp/vita-backup-$TIMESTAMP"
LOCAL_BACKUP_DIR="./backups/$ENVIRONMENT"

# Create backup directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOCAL_BACKUP_DIR"

echo "📁 Backup Configuration:"
echo "   📦 Main bucket: $BACKUP_BUCKET"
echo "   📂 Backup directory: $BACKUP_DIR"
echo "   💾 Local backup: $LOCAL_BACKUP_DIR"
echo ""

# =============================================================================
# DATABASE BACKUPS
# =============================================================================

echo "🗄️  DATABASE BACKUPS"
echo "==================="

# MySQL/MariaDB Backup (ERPNext)
echo "🔵 MySQL Database Backup..."
if docker ps | grep -q mariadb; then
    docker exec vita-strategies-mariadb-1 mysqldump \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --all-databases \
        --single-transaction \
        --routines \
        --triggers > "$BACKUP_DIR/mysql_backup_$TIMESTAMP.sql"
    
    # Compress the backup
    gzip "$BACKUP_DIR/mysql_backup_$TIMESTAMP.sql"
    echo "✅ MySQL backup created: mysql_backup_$TIMESTAMP.sql.gz"
else
    echo "⚠️  MySQL container not running, skipping MySQL backup"
fi

# PostgreSQL Backup (Metabase, Windmill)
echo "🟢 PostgreSQL Database Backup..."
if docker ps | grep -q postgres; then
    docker exec vita-strategies-postgres-1 pg_dumpall \
        -U postgres > "$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"
    
    # Compress the backup
    gzip "$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"
    echo "✅ PostgreSQL backup created: postgres_backup_$TIMESTAMP.sql.gz"
else
    echo "⚠️  PostgreSQL container not running, skipping PostgreSQL backup"
fi

echo ""

# =============================================================================
# VOLUME BACKUPS
# =============================================================================

echo "💽 DOCKER VOLUME BACKUPS"
echo "========================"

# Get list of named volumes
volumes=$(docker volume ls --format "{{.Name}}" | grep "vita-strategies" || echo "")

if [[ -n "$volumes" ]]; then
    echo "📦 Found volumes to backup:"
    echo "$volumes" | while read -r volume; do
        echo "   • $volume"
    done
    echo ""
    
    # Backup each volume
    echo "$volumes" | while read -r volume; do
        echo "💾 Backing up volume: $volume"
        
        # Create volume backup using tar
        docker run --rm \
            -v "$volume":/source \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf "/backup/${volume}_$TIMESTAMP.tar.gz" -C /source .
        
        echo "✅ Volume backup created: ${volume}_$TIMESTAMP.tar.gz"
    done
else
    echo "⚠️  No Docker volumes found"
fi

echo ""

# =============================================================================
# APPLICATION DATA BACKUPS
# =============================================================================

echo "📋 APPLICATION DATA BACKUPS"
echo "=========================="

# ERPNext specific backups
echo "🔷 ERPNext Application Backup..."
if docker ps | grep -q erpnext; then
    # Backup ERPNext sites
    docker exec vita-strategies-erpnext-1 bench backup --with-files
    
    # Copy backups from container
    docker cp vita-strategies-erpnext-1:/home/frappe/frappe-bench/sites/site1.local/private/backups \
        "$BACKUP_DIR/erpnext_backups_$TIMESTAMP" 2>/dev/null || echo "⚠️  Could not copy ERPNext backups"
    
    echo "✅ ERPNext backup attempted"
else
    echo "⚠️  ERPNext container not running"
fi

# Configuration backups
echo "⚙️  Configuration Backup..."
cp -r environments/ "$BACKUP_DIR/environments_$TIMESTAMP" 2>/dev/null || echo "⚠️  Could not copy environments"
cp docker-compose-persistent.yml "$BACKUP_DIR/docker-compose_$TIMESTAMP.yml" 2>/dev/null || echo "⚠️  Could not copy docker-compose"
cp -r infrastructure/ "$BACKUP_DIR/infrastructure_$TIMESTAMP" 2>/dev/null || echo "⚠️  Could not copy infrastructure"

echo "✅ Configuration backup completed"
echo ""

# =============================================================================
# CREATE BACKUP MANIFEST
# =============================================================================

echo "📋 CREATING BACKUP MANIFEST"
echo "=========================="

MANIFEST_FILE="$BACKUP_DIR/backup_manifest_$TIMESTAMP.json"

cat > "$MANIFEST_FILE" << EOF
{
  "backup_info": {
    "timestamp": "$TIMESTAMP",
    "date": "$BACKUP_DATE",
    "environment": "$ENVIRONMENT",
    "backup_type": "full",
    "created_by": "vita-strategies-backup-script"
  },
  "backup_location": {
    "gcs_bucket": "$BACKUP_BUCKET",
    "local_directory": "$BACKUP_DIR"
  },
  "components": {
    "databases": {
      "mysql": "$(ls $BACKUP_DIR/mysql_backup_*.sql.gz 2>/dev/null | wc -l | tr -d ' ') file(s)",
      "postgresql": "$(ls $BACKUP_DIR/postgres_backup_*.sql.gz 2>/dev/null | wc -l | tr -d ' ') file(s)"
    },
    "volumes": {
      "docker_volumes": "$(ls $BACKUP_DIR/*_$TIMESTAMP.tar.gz 2>/dev/null | wc -l | tr -d ' ') file(s)"
    },
    "applications": {
      "erpnext": "$(if [[ -d $BACKUP_DIR/erpnext_backups_$TIMESTAMP ]]; then echo 'included'; else echo 'not_available'; fi)",
      "configuration": "included"
    }
  },
  "backup_size": {
    "total_files": $(find "$BACKUP_DIR" -type f | wc -l | tr -d ' '),
    "total_size_bytes": $(du -sb "$BACKUP_DIR" | cut -f1)
  }
}
EOF

echo "✅ Backup manifest created"
echo ""

# =============================================================================
# UPLOAD TO GOOGLE CLOUD STORAGE
# =============================================================================

echo "☁️  UPLOADING TO GOOGLE CLOUD STORAGE"
echo "====================================="

# Check if gsutil is available
if command -v gsutil &> /dev/null; then
    # Create bucket if it doesn't exist
    if ! gsutil ls "gs://$BACKUP_BUCKET" &> /dev/null; then
        echo "📦 Creating backup bucket: $BACKUP_BUCKET"
        gsutil mb "gs://$BACKUP_BUCKET"
        
        # Set lifecycle policy to delete backups older than 30 days
        cat > /tmp/lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 30}
      }
    ]
  }
}
EOF
        gsutil lifecycle set /tmp/lifecycle.json "gs://$BACKUP_BUCKET"
        rm /tmp/lifecycle.json
    fi
    
    # Upload backup files
    echo "📤 Uploading backup files..."
    gsutil -m cp -r "$BACKUP_DIR/*" "gs://$BACKUP_BUCKET/$TIMESTAMP/"
    
    # Copy to local backup directory
    cp -r "$BACKUP_DIR"/* "$LOCAL_BACKUP_DIR/"
    
    echo "✅ Backup uploaded to: gs://$BACKUP_BUCKET/$TIMESTAMP/"
    echo "💾 Local backup stored in: $LOCAL_BACKUP_DIR"
    
    # Clean up temporary directory
    rm -rf "$BACKUP_DIR"
    
else
    echo "⚠️  gsutil not available, keeping local backup only"
    echo "💾 Backup stored locally in: $BACKUP_DIR"
fi

echo ""

# =============================================================================
# BACKUP VERIFICATION
# =============================================================================

echo "🔍 BACKUP VERIFICATION"
echo "====================="

backup_files=0
total_size=0

if command -v gsutil &> /dev/null && gsutil ls "gs://$BACKUP_BUCKET/$TIMESTAMP/" &> /dev/null; then
    backup_files=$(gsutil ls "gs://$BACKUP_BUCKET/$TIMESTAMP/**" | wc -l | tr -d ' ')
    total_size=$(gsutil du -s "gs://$BACKUP_BUCKET/$TIMESTAMP/" | awk '{print $1}')
    
    echo "✅ Cloud backup verification:"
    echo "   📁 Files: $backup_files"
    echo "   💾 Size: $total_size bytes"
    echo "   🔗 Location: gs://$BACKUP_BUCKET/$TIMESTAMP/"
else
    # Check local backup
    if [[ -d "$LOCAL_BACKUP_DIR" ]]; then
        backup_files=$(find "$LOCAL_BACKUP_DIR" -type f | wc -l | tr -d ' ')
        total_size=$(du -sb "$LOCAL_BACKUP_DIR" | cut -f1)
        
        echo "✅ Local backup verification:"
        echo "   📁 Files: $backup_files"
        echo "   💾 Size: $total_size bytes"
        echo "   📂 Location: $LOCAL_BACKUP_DIR"
    fi
fi

echo ""

# =============================================================================
# BACKUP SUMMARY
# =============================================================================

echo "📊 BACKUP SUMMARY"
echo "=================="
echo "🎯 Environment: $ENVIRONMENT"
echo "⏰ Started: $BACKUP_DATE"
echo "⏱️  Completed: $(date +"%Y-%m-%d %H:%M:%S UTC")"
echo "📁 Files backed up: $backup_files"
echo "💾 Total size: $total_size bytes"

if command -v gsutil &> /dev/null; then
    echo "☁️  Cloud storage: ✅ Available"
    echo "🔗 Backup location: gs://$BACKUP_BUCKET/$TIMESTAMP/"
else
    echo "☁️  Cloud storage: ❌ Not available"
    echo "📂 Local backup: $LOCAL_BACKUP_DIR"
fi

echo ""
echo "🎉 BACKUP COMPLETED SUCCESSFULLY!"

# =============================================================================
# CLEANUP OLD BACKUPS (LOCAL)
# =============================================================================

if [[ -d "./backups/$ENVIRONMENT" ]]; then
    echo ""
    echo "🧹 CLEANING OLD LOCAL BACKUPS"
    echo "============================="
    
    # Keep only last 7 local backups
    backup_count=$(ls -1 "./backups/$ENVIRONMENT" | wc -l | tr -d ' ')
    
    if [[ $backup_count -gt 7 ]]; then
        echo "📊 Found $backup_count local backups, keeping latest 7"
        ls -1t "./backups/$ENVIRONMENT" | tail -n +8 | while read -r old_backup; do
            echo "🗑️  Removing old backup: $old_backup"
            rm -rf "./backups/$ENVIRONMENT/$old_backup"
        done
        echo "✅ Local backup cleanup completed"
    else
        echo "📊 Found $backup_count local backups (keeping all)"
    fi
fi

echo ""
echo "💾 Backup script completed!"
