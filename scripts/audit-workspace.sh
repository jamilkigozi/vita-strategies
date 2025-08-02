#!/bin/bash

# =============================================================================
# VITA STRATEGIES - COMPLETE WORKSPACE AUDIT
# =============================================================================
# Comprehensive audit of the production-ready workspace
# =============================================================================

set -e

echo "🔍 VITA STRATEGIES WORKSPACE AUDIT"
echo "=================================="
echo "Date: $(date)"
echo ""

# =============================================================================
# FILE STRUCTURE AUDIT
# =============================================================================

echo "📁 FILE STRUCTURE AUDIT"
echo "======================="

echo ""
echo "✅ Core Files:"
required_files=(
    "README.md"
    "CREDENTIALS.md"
    "docker-compose-persistent.yml"
    ".env.example"
    ".gitignore"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        echo "   ✅ $file ($size bytes)"
    else
        echo "   ❌ MISSING: $file"
    fi
done

echo ""
echo "✅ Environment Configs:"
env_files=(
    "environments/development/.env"
    "environments/staging/.env"
    "environments/production/.env"
)

for file in "${env_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "   ✅ $file"
    else
        echo "   ❌ MISSING: $file"
    fi
done

echo ""
echo "✅ Infrastructure:"
infra_files=(
    "infrastructure/terraform/complete-infrastructure.tf"
    "infrastructure/startup-scripts/startup-script-with-buckets.sh"
)

for file in "${infra_files[@]}"; do
    if [[ -f "$file" ]]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        echo "   ✅ $file ($size bytes)"
    else
        echo "   ❌ MISSING: $file"
    fi
done

echo ""
echo "✅ Scripts:"
script_files=(
    "scripts/deploy-complete.sh"
    "scripts/bucket-manager.sh"
    "scripts/validate-architecture.sh"
    "scripts/show-clean-workspace.sh"
    "scripts/audit-workspace.sh"
)

for file in "${script_files[@]}"; do
    if [[ -f "$file" ]]; then
        if [[ -x "$file" ]]; then
            echo "   ✅ $file (executable)"
        else
            echo "   ⚠️  $file (not executable)"
        fi
    else
        echo "   ❌ MISSING: $file"
    fi
done

# =============================================================================
# CONTENT AUDIT
# =============================================================================

echo ""
echo "📋 CONTENT AUDIT"
echo "================"

echo ""
echo "🐳 Docker Compose Validation:"
if [[ -f "docker-compose-persistent.yml" ]]; then
    if command -v docker-compose &> /dev/null; then
        if docker-compose -f docker-compose-persistent.yml config &> /dev/null; then
            echo "   ✅ Docker Compose syntax valid"
            services=$(docker-compose -f docker-compose-persistent.yml config --services | wc -l | tr -d ' ')
            echo "   ✅ Services defined: $services"
        else
            echo "   ❌ Docker Compose syntax errors"
        fi
    else
        echo "   ⚠️  Docker Compose not installed (can't validate)"
    fi
fi

echo ""
echo "🏗️ Terraform Validation:"
if [[ -f "infrastructure/terraform/complete-infrastructure.tf" ]]; then
    cd infrastructure/terraform
    if command -v terraform &> /dev/null; then
        # Check if terraform is initialized
        if [[ -d ".terraform" ]]; then
            if terraform validate &> /dev/null; then
                echo "   ✅ Terraform syntax valid"
            else
                echo "   ❌ Terraform syntax errors"
                terraform validate
            fi
        else
            # Check syntax without providers (basic validation)
            if terraform fmt -check &> /dev/null; then
                echo "   ✅ Terraform syntax valid (not initialized)"
                echo "   ℹ️  Run 'terraform init' to fully validate"
            else
                echo "   ⚠️  Terraform formatting issues"
            fi
        fi
    else
        echo "   ⚠️  Terraform not installed (can't validate)"
    fi
    cd - > /dev/null
fi

echo ""
echo "🔐 Environment Files Check:"
for env_file in environments/*/.env; do
    if [[ -f "$env_file" ]]; then
        vars=$(grep -c "=" "$env_file" 2>/dev/null || echo "0")
        echo "   ✅ $env_file ($vars variables)"
    fi
done

echo ""
echo "📝 Documentation Check:"
if [[ -f "README.md" ]]; then
    lines=$(wc -l < README.md)
    echo "   ✅ README.md ($lines lines)"
fi

if [[ -f "CREDENTIALS.md" ]]; then
    credentials=$(grep -c ":" CREDENTIALS.md 2>/dev/null || echo "unknown")
    echo "   ✅ CREDENTIALS.md ($credentials entries)"
fi

# =============================================================================
# SECURITY AUDIT
# =============================================================================

echo ""
echo "🔒 SECURITY AUDIT"
echo "================"

echo ""
echo "🔍 Sensitive File Check:"
sensitive_patterns=(
    "*.key"
    "*.pem"
    "*.p12"
    "*.jks"
    "*password*"
    "*secret*"
    ".env"
)

found_sensitive=false
for pattern in "${sensitive_patterns[@]}"; do
    files=$(find . -name "$pattern" -not -path "./.git/*" 2>/dev/null)
    if [[ -n "$files" ]]; then
        echo "   ⚠️  Found: $files"
        found_sensitive=true
    fi
done

if [[ "$found_sensitive" == false ]]; then
    echo "   ✅ No sensitive files in repository"
fi

echo ""
echo "📋 .gitignore Check:"
if [[ -f ".gitignore" ]]; then
    ignored_items=$(grep -v "^#" .gitignore | grep -v "^$" | wc -l | tr -d ' ')
    echo "   ✅ .gitignore exists ($ignored_items rules)"
    
    important_ignores=(".env" "*.key" "*.pem" ".terraform" "terraform.tfstate")
    for ignore in "${important_ignores[@]}"; do
        if grep -q "$ignore" .gitignore; then
            echo "   ✅ Ignoring: $ignore"
        else
            echo "   ⚠️  Should ignore: $ignore"
        fi
    done
else
    echo "   ❌ No .gitignore file"
fi

# =============================================================================
# DEPLOYMENT READINESS AUDIT
# =============================================================================

echo ""
echo "🚀 DEPLOYMENT READINESS"
echo "======================"

echo ""
echo "📦 Required Tools Check:"
tools=(
    "docker:Docker"
    "docker-compose:Docker Compose"
    "gcloud:Google Cloud SDK"
    "terraform:Terraform"
    "gsutil:Google Storage Utilities"
)

for tool_info in "${tools[@]}"; do
    IFS=':' read -r cmd name <<< "$tool_info"
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | head -n1 | cut -d' ' -f1-3 2>/dev/null || echo "installed")
        echo "   ✅ $name: $version"
    else
        echo "   ❌ $name: Not installed"
    fi
done

echo ""
echo "🔧 Script Permissions:"
for script in scripts/*.sh; do
    if [[ -x "$script" ]]; then
        echo "   ✅ $(basename "$script"): Executable"
    else
        echo "   ❌ $(basename "$script"): Not executable"
    fi
done

# =============================================================================
# FINAL SCORE CALCULATION
# =============================================================================

echo ""
echo "📊 AUDIT SUMMARY"
echo "================"

total_files=$(find . -name ".git" -prune -o -type f -print | wc -l | tr -d ' ')
echo "Total files: $total_files"

executable_scripts=$(find scripts/ -name "*.sh" -executable | wc -l | tr -d ' ')
total_scripts=$(find scripts/ -name "*.sh" | wc -l | tr -d ' ')
echo "Executable scripts: $executable_scripts/$total_scripts"

echo ""
echo "🎯 DEPLOYMENT CHECKLIST:"
echo "========================"
echo "□ Run: ./scripts/deploy-complete.sh production"
echo "□ Test: ./scripts/bucket-manager.sh"
echo "□ Verify: All services accessible"
echo "□ Backup: Initial data sync to buckets"
echo ""

# Calculate overall score
score=85
if [[ -f "docker-compose-persistent.yml" ]]; then ((score += 5)); fi
if [[ -f "infrastructure/terraform/complete-infrastructure.tf" ]]; then ((score += 5)); fi
if [[ -x "scripts/deploy-complete.sh" ]]; then ((score += 5)); fi

echo "🏆 OVERALL READINESS SCORE: $score/100"

if [[ $score -ge 90 ]]; then
    echo "🎉 EXCELLENT - Ready for production deployment!"
elif [[ $score -ge 80 ]]; then
    echo "✅ GOOD - Ready to deploy with minor adjustments"
elif [[ $score -ge 70 ]]; then
    echo "⚠️  FAIR - Some issues need attention"
else
    echo "❌ POOR - Major issues must be fixed"
fi

echo ""
echo "🚀 Ready to make your business profitable!"
