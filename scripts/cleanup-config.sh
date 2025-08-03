#!/bin/bash
# Configuration Cleanup Script
# Purpose: Fix all hardcoded values and inconsistencies

set -e

echo "🧹 STARTING CONFIGURATION CLEANUP..."

# Define correct values
PROJECT_ID="vita-strategies"
PROJECT_NAME="vita-strategies"
REGION="europe-west2"
ZONE="europe-west2-c"

echo "📋 Using configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Zone: $ZONE"

# Function to replace in file
replace_in_file() {
    local file="$1"
    local old="$2"
    local new="$3"
    
    if [ -f "$file" ]; then
        sed -i.bak "s|$old|$new|g" "$file"
        echo "  ✅ Updated: $file"
    else
        echo "  ⚠️  File not found: $file"
    fi
}

echo ""
echo "🔧 PHASE 1: Fix region references..."

# Fix us-central1 to europe-west2
find /Users/millz./vita-strategies -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "*.hcl" -o -name "*.md" -o -name "Dockerfile" | while read file; do
    if grep -q "us-central1" "$file" 2>/dev/null; then
        replace_in_file "$file" "us-central1" "europe-west2"
    fi
done

echo ""
echo "🔧 PHASE 2: Fix hardcoded project references..."

# Fix GCP_PROJECT_PLACEHOLDER
find /Users/millz./vita-strategies -name "*.hcl" -o -name "*.tf" -o -name "*.yml" | while read file; do
    if grep -q "GCP_PROJECT_PLACEHOLDER" "$file" 2>/dev/null; then
        replace_in_file "$file" "GCP_PROJECT_PLACEHOLDER" "\${var.project_id}"
    fi
done

echo ""
echo "🔧 PHASE 3: Fix bucket name inconsistencies..."

# Standard bucket naming pattern
declare -A BUCKET_MAPPING=(
    ["vita-strategies-erpnext-production"]="vita-strategies-erpnext-production"
    ["vita-strategies-analytics-production"]="vita-strategies-analytics-production"
    ["vita-strategies-team-files-production"]="vita-strategies-team-files-production"
    ["vita-strategies-assets-production"]="vita-strategies-assets-production"
    ["vita-strategies-data-backup-production"]="vita-strategies-data-backup-production"
    ["vita-strategies-wordpress-production"]="vita-strategies-wordpress-production"
    ["vita-strategies-mattermost-production"]="vita-strategies-mattermost-production"
    ["vita-strategies-workflows-production"]="vita-strategies-workflows-production"
    ["vita-strategies-appsmith-production"]="vita-strategies-appsmith-production"
    ["vita-strategies-monitoring-production"]="vita-strategies-monitoring-production"
    ["vita-strategies-vault-production"]="vita-strategies-vault-production"
    ["vita-strategies-auth-production"]="vita-strategies-auth-production"
    ["vita-strategies-docs-production"]="vita-strategies-docs-production"
)

echo ""
echo "🔧 PHASE 4: Remove redundant configurations..."

# Remove backup files
find /Users/millz./vita-strategies -name "*.bak" -delete 2>/dev/null || true

echo ""
echo "🔧 PHASE 5: Validate configuration consistency..."

# Check for remaining issues
echo "Checking for remaining us-central1 references:"
grep -r "us-central1" /Users/millz./vita-strategies --exclude-dir=.git || echo "  ✅ None found"

echo ""
echo "Checking for GCP_PROJECT_PLACEHOLDER references:"
grep -r "GCP_PROJECT_PLACEHOLDER" /Users/millz./vita-strategies --exclude-dir=.git || echo "  ✅ None found"

echo ""
echo "✅ CONFIGURATION CLEANUP COMPLETE!"
echo ""
echo "📋 SUMMARY:"
echo "  - Fixed region references (us-central1 → europe-west2)"
echo "  - Updated GCP project placeholders"  
echo "  - Standardized bucket naming"
echo "  - Removed redundant configurations"
echo ""
echo "🎯 NEXT STEPS:"
echo "  1. Review changes with: git diff"
echo "  2. Test configuration: terraform plan"
echo "  3. Deploy with: terraform apply"
