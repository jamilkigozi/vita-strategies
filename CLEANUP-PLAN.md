# 🧹 CONFIGURATION CLEANUP PLAN

## IDENTIFIED ISSUES

### 1. Region Inconsistencies
- **Found**: `us-central1` hardcoded in multiple files
- **Should Be**: `europe-west2` (from variables.tf)
- **Files Affected**: 15+ files

### 2. Project ID Issues
- **Found**: Mixed usage of `vita-strategies`, `GCP_PROJECT_PLACEHOLDER`, random project names
- **Should Be**: Use `var.project_id` consistently
- **Files Affected**: 20+ files

### 3. Bucket Naming Problems
- **Found**: Hardcoded `vita-strategies-*` bucket names
- **Should Be**: `${var.project_name}-*` pattern
- **Files Affected**: Infrastructure and app configs

### 4. GCP Service Account References
- **Found**: Hardcoded paths like `/opt/openbao/config/gcp-kms.json`
- **Should Be**: Configurable via environment variables

## CLEANUP ACTIONS NEEDED

### Phase 1: Infrastructure Variables
✅ **Fix variables.tf** - Ensure consistent defaults
✅ **Fix main.tf** - Use variables instead of hardcoded values  
✅ **Fix compute.tf** - Use proper region/zone variables
✅ **Fix storage.tf** - Use variable-based bucket naming
✅ **Fix security.tf** - Use project_id variable consistently

### Phase 2: Application Configurations  
✅ **OpenBao config** - Fix GCP project references
✅ **Docker Compose files** - Use environment variables
✅ **Application configs** - Remove hardcoded regions/projects
✅ **Credential Audit** - Update with correct values

### Phase 3: Environment Templates
✅ **Update .env.template** - Correct default values
✅ **Update documentation** - Remove inconsistent references

## CONFIRMED CONFIGURATION ✅

Based on your confirmation:
```hcl
project_id = "vita-strategies"     # ✅ CONFIRMED
project_name = "vita-strategies"   # ✅ CONFIRMED  
region = "europe-west2"           # ✅ CONFIRMED (London)
zone = "europe-west2-c"           # ✅ CONFIRMED
environment = "production"        # ✅ CONFIRMED
```

## BUCKET NAMING STANDARD
```
${project_name}-${service}-${environment}
Examples:
- vita-strategies-wordpress-production
- vita-strategies-analytics-production
- vita-strategies-vault-production
```

## NEXT STEPS - READY FOR DEPLOYMENT! 🚀
1. ✅ Infrastructure variables confirmed
2. ✅ Application configurations cleaned  
3. ✅ Configuration consistency verified
4. ✅ Documentation updated
5. 🎯 **NOW: Deploy infrastructure and services**
