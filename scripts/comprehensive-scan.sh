#!/bin/bash

# =============================================================================
# VITA STRATEGIES - COMPREHENSIVE WORKSPACE SCAN & RECTIFICATION
# =============================================================================
# Scans every file and folder to identify and fix missing components
# =============================================================================

set -e

echo "🔍 VITA STRATEGIES - COMPREHENSIVE WORKSPACE SCAN"
echo "================================================="
echo "📅 Scan Date: $(date)"
echo ""

# =============================================================================
# FILE STRUCTURE ANALYSIS
# =============================================================================

echo "📁 ANALYZING FILE STRUCTURE..."
echo "=============================="

# Count files by type
total_files=$(find . -name ".git" -prune -o -type f -print | wc -l | tr -d ' ')
scripts_count=$(find scripts/ -name "*.sh" | wc -l | tr -d ' ')
config_files=$(find . -name "*.yml" -o -name "*.tf" -o -name "*.env" | grep -v ".git" | wc -l | tr -d ' ')
doc_files=$(find . -name "*.md" | grep -v ".git" | wc -l | tr -d ' ')

echo "📊 File Count Summary:"
echo "   Total files: $total_files"
echo "   Scripts: $scripts_count"
echo "   Config files: $config_files"
echo "   Documentation: $doc_files"
echo ""

# =============================================================================
# MISSING COMPONENTS DETECTION
# =============================================================================

echo "🚨 MISSING COMPONENTS DETECTION"
echo "==============================="

missing_components=()

# Check for essential files
essential_files=(
    "docker-compose-persistent.yml:Main Docker configuration"
    "infrastructure/terraform/complete-infrastructure.tf:Terraform infrastructure"
    "CREDENTIALS.md:Login credentials"
    "README.md:Main documentation"
    "INSTALL.md:Installation guide"
    ".gitignore:Git ignore rules"
    ".env.example:Environment template"
)

echo "✅ Essential Files Check:"
for file_info in "${essential_files[@]}"; do
    IFS=':' read -r file description <<< "$file_info"
    if [[ -f "$file" ]]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        echo "   ✅ $description: $file ($size bytes)"
    else
        echo "   ❌ MISSING: $description ($file)"
        missing_components+=("$file")
    fi
done
echo ""

# Check for environment files
echo "🌍 Environment Configuration Check:"
env_dirs=("development" "staging" "production")
for env in "${env_dirs[@]}"; do
    env_file="environments/$env/.env"
    if [[ -f "$env_file" ]]; then
        vars=$(grep -c "=" "$env_file" 2>/dev/null || echo "0")
        echo "   ✅ $env environment: $vars variables"
    else
        echo "   ❌ MISSING: $env environment"
        missing_components+=("$env_file")
    fi
done
echo ""

# Check for deployment scripts
echo "🚀 Deployment Scripts Check:"
required_scripts=(
    "scripts/deploy-complete.sh:Complete deployment"
    "scripts/deploy-from-gcp-cloudshell.sh:GCP Cloud Shell deployment"
    "scripts/bucket-manager.sh:Data management"
    "scripts/export-business.sh:Business export"
    "scripts/sync-to-laptop.sh:Laptop backup"
    "scripts/audit-workspace.sh:Workspace audit"
    "scripts/backup-data.sh:Data backup"
    "scripts/dev-helper.sh:Development helper"
    "scripts/monitor-production.sh:Production monitoring"
)

for script_info in "${required_scripts[@]}"; do
    IFS=':' read -r script description <<< "$script_info"
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            echo "   ✅ $description: executable"
        else
            echo "   ⚠️  $description: not executable"
            chmod +x "$script"
            echo "   🔧 Fixed: made executable"
        fi
    else
        echo "   ❌ MISSING: $description ($script)"
        missing_components+=("$script")
    fi
done
echo ""

# Check for CI/CD pipeline
echo "🔄 CI/CD Pipeline Check:"
if [[ -f ".github/workflows/ci-cd.yml" ]]; then
    if [[ -s ".github/workflows/ci-cd.yml" ]]; then
        jobs=$(grep -c "name:.*job\|name: " ".github/workflows/ci-cd.yml" || echo "0")
        echo "   ✅ GitHub Actions pipeline: configured ($jobs components)"
    else
        echo "   ⚠️  GitHub Actions pipeline: empty file"
        missing_components+=(".github/workflows/ci-cd.yml")
    fi
else
    echo "   ❌ MISSING: GitHub Actions pipeline"
    missing_components+=(".github/workflows/ci-cd.yml")
fi
echo ""

# =============================================================================
# CONTENT VALIDATION
# =============================================================================

echo "🔍 CONTENT VALIDATION"
echo "====================="

# Validate Docker Compose
echo "🐳 Docker Compose Validation:"
if [[ -f "docker-compose-persistent.yml" ]]; then
    if command -v docker-compose &> /dev/null; then
        if docker-compose -f docker-compose-persistent.yml config --quiet 2>/dev/null; then
            services=$(docker-compose -f docker-compose-persistent.yml config --services | wc -l | tr -d ' ')
            echo "   ✅ Syntax valid ($services services)"
        else
            echo "   ❌ Syntax errors detected"
            missing_components+=("docker-compose-syntax")
        fi
    else
        echo "   ⚠️  Docker Compose not installed (cannot validate)"
    fi
else
    echo "   ❌ Docker Compose file missing"
    missing_components+=("docker-compose-persistent.yml")
fi
echo ""

# Validate Terraform
echo "🏗️ Terraform Validation:"
if [[ -f "infrastructure/terraform/complete-infrastructure.tf" ]]; then
    cd infrastructure/terraform
    if command -v terraform &> /dev/null; then
        if terraform fmt -check &> /dev/null; then
            echo "   ✅ Terraform formatting correct"
            
            # Check if initialized
            if [[ -d ".terraform" ]]; then
                if terraform validate &> /dev/null; then
                    echo "   ✅ Terraform syntax valid"
                else
                    echo "   ❌ Terraform validation errors"
                    missing_components+=("terraform-validation")
                fi
            else
                echo "   ℹ️  Terraform not initialized (run 'terraform init')"
            fi
        else
            echo "   ⚠️  Terraform formatting issues"
            terraform fmt
            echo "   🔧 Fixed: formatted Terraform files"
        fi
    else
        echo "   ⚠️  Terraform not installed (cannot validate)"
    fi
    cd - > /dev/null
else
    echo "   ❌ Terraform configuration missing"
    missing_components+=("infrastructure/terraform/complete-infrastructure.tf")
fi
echo ""

# =============================================================================
# SECURITY SCAN
# =============================================================================

echo "🔒 SECURITY SCAN"
echo "================"

# Check for exposed secrets
echo "🔍 Scanning for exposed secrets:"
secret_patterns=("password" "secret" "key" "token" "api_key")
found_secrets=false

for pattern in "${secret_patterns[@]}"; do
    matches=$(grep -r -i "$pattern" . --exclude-dir=.git --include="*.md" --include="*.txt" --include="*.json" --include="*.yml" --include="*.yaml" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $matches -gt 0 ]]; then
        echo "   ⚠️  Found $matches potential secrets containing '$pattern'"
        found_secrets=true
    fi
done

if [[ "$found_secrets" == false ]]; then
    echo "   ✅ No exposed secrets detected in documentation"
fi
echo ""

# Check .gitignore
echo "📋 .gitignore Validation:"
if [[ -f ".gitignore" ]]; then
    required_ignores=(".env" "*.key" "*.pem" ".terraform" "terraform.tfstate" "*.log")
    missing_ignores=()
    
    for ignore in "${required_ignores[@]}"; do
        if grep -q "$ignore" .gitignore; then
            echo "   ✅ Ignoring: $ignore"
        else
            echo "   ⚠️  Should ignore: $ignore"
            missing_ignores+=("$ignore")
        fi
    done
    
    if [[ ${#missing_ignores[@]} -gt 0 ]]; then
        echo "   🔧 Adding missing ignore patterns..."
        for ignore in "${missing_ignores[@]}"; do
            echo "$ignore" >> .gitignore
        done
        echo "   ✅ Updated .gitignore"
    fi
else
    echo "   ❌ .gitignore missing"
    missing_components+=(".gitignore")
fi
echo ""

# =============================================================================
# INTEGRATION TESTING
# =============================================================================

echo "🧪 INTEGRATION TESTING"
echo "======================"

# Test script execution permissions
echo "🔧 Script Permissions Test:"
script_issues=0
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        if [[ ! -x "$script" ]]; then
            echo "   🔧 Fixing: $script (making executable)"
            chmod +x "$script"
            script_issues=$((script_issues + 1))
        fi
    fi
done

if [[ $script_issues -eq 0 ]]; then
    echo "   ✅ All scripts are executable"
else
    echo "   🔧 Fixed $script_issues script permission issues"
fi
echo ""

# Test environment file structure
echo "🌍 Environment File Structure:"
for env_file in environments/*/.env; do
    if [[ -f "$env_file" ]]; then
        env_name=$(basename $(dirname "$env_file"))
        
        # Check for required variables
        required_vars=("DOMAIN" "ENVIRONMENT" "MYSQL_ROOT_PASSWORD" "POSTGRES_PASSWORD")
        missing_vars=()
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$env_file"; then
                echo "   ✅ $env_name: $var defined"
            else
                echo "   ⚠️  $env_name: $var missing"
                missing_vars+=("$var")
            fi
        done
        
        if [[ ${#missing_vars[@]} -gt 0 ]]; then
            missing_components+=("env-vars-$env_name")
        fi
    fi
done
echo ""

# =============================================================================
# DEPLOYMENT READINESS CHECK
# =============================================================================

echo "🚀 DEPLOYMENT READINESS CHECK"
echo "============================="

# Check for required tools
echo "📦 Required Tools:"
tools=("docker" "docker-compose" "gcloud" "terraform" "gsutil")
missing_tools=()

for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$($tool --version 2>&1 | head -n1 | cut -d' ' -f1-3 || echo "installed")
        echo "   ✅ $tool: $version"
    else
        echo "   ❌ $tool: Not installed"
        missing_tools+=("$tool")
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    missing_components+=("tools: ${missing_tools[*]}")
fi
echo ""

# =============================================================================
# MISSING COMPONENTS SUMMARY
# =============================================================================

echo "📋 MISSING COMPONENTS SUMMARY"
echo "============================="

if [[ ${#missing_components[@]} -eq 0 ]]; then
    echo "🎉 NO MISSING COMPONENTS FOUND!"
    echo "Your workspace is complete and ready for deployment."
else
    echo "⚠️  Found ${#missing_components[@]} missing components:"
    for component in "${missing_components[@]}"; do
        echo "   ❌ $component"
    done
fi
echo ""

# =============================================================================
# RECTIFICATION RECOMMENDATIONS
# =============================================================================

echo "🔧 RECTIFICATION RECOMMENDATIONS"
echo "================================"

if [[ ${#missing_components[@]} -gt 0 ]]; then
    echo "To fix missing components:"
    echo ""
    
    # Check if any essential files are missing
    for component in "${missing_components[@]}"; do
        case $component in
            *".env")
                echo "📝 Create missing environment file:"
                echo "   cp .env.example $component"
                echo "   # Edit $component with appropriate values"
                echo ""
                ;;
            *".sh")
                echo "📝 Create missing script: $component"
                echo "   # Script template needed"
                echo ""
                ;;
            "docker-compose-syntax")
                echo "🐳 Fix Docker Compose syntax:"
                echo "   docker-compose -f docker-compose-persistent.yml config"
                echo ""
                ;;
            "terraform-validation")
                echo "🏗️ Fix Terraform validation:"
                echo "   cd infrastructure/terraform && terraform init && terraform validate"
                echo ""
                ;;
        esac
    done
else
    echo "✅ No rectification needed - workspace is complete!"
fi
echo ""

# =============================================================================
# FINAL SCORE AND RECOMMENDATIONS
# =============================================================================

# Calculate completion score
total_checks=20
issues=${#missing_components[@]}
score=$(( (total_checks - issues) * 100 / total_checks ))

echo "🏆 WORKSPACE COMPLETENESS SCORE"
echo "==============================="
echo "Score: $score/100"
echo ""

if [[ $score -ge 95 ]]; then
    echo "🎉 EXCELLENT - Workspace is production-ready!"
    echo "✅ All components present and configured"
    echo "🚀 Ready for deployment"
elif [[ $score -ge 85 ]]; then
    echo "✅ GOOD - Minor issues to address"
    echo "⚠️  $issues components need attention"
    echo "🔧 Quick fixes needed"
elif [[ $score -ge 70 ]]; then
    echo "⚠️  FAIR - Several issues to resolve"
    echo "❌ $issues missing components"
    echo "🛠️  Moderate work needed"
else
    echo "❌ POOR - Major issues require attention"
    echo "🚨 $issues critical missing components"
    echo "🏗️  Significant work needed"
fi

echo ""
echo "📊 SUMMARY:"
echo "   Total files: $total_files"
echo "   Scripts: $scripts_count"
echo "   Missing components: ${#missing_components[@]}"
echo "   Completion: $score%"
echo ""

if [[ $score -ge 90 ]]; then
    echo "🎯 NEXT STEPS:"
    echo "1. Deploy: ./scripts/deploy-complete.sh production"
    echo "2. Test: ./scripts/bucket-manager.sh"
    echo "3. Verify: Check all services"
fi

echo ""
echo "🔍 Workspace scan complete!"
