# CONFIGURATION CLEANUP - CRITICAL FIXES

## What I found and what needs to be your actual values:

### 1. PROJECT CONFIGURATION
Current variables.tf shows:
- `project_id = "vita-strategies"`  
- `region = "europe-west2"`
- `zone = "europe-west2-c"`

### 2. CRITICAL QUESTIONS FOR YOU:

1. **What is your ACTUAL GCP Project ID?** (this might not be "vita-strategies")
2. **Do you want to keep europe-west2 region?** (instead of us-central1 scattered in code)
3. **Do you have existing GCS buckets we need to import?**

### 3. IMMEDIATE FIXES NEEDED:

Before deployment, I need to know:
```bash
# What should these values actually be?
PROJECT_ID="your-actual-gcp-project-id"
REGION="europe-west2"  # or your preferred region
ZONE="europe-west2-c"   # or your preferred zone
```

### 4. QUICK FIXES I CAN DO NOW:

1. ✅ Fixed OpenBao region: us-central1 → europe-west2  
2. 🔧 Need your actual project ID to fix project references
3. 🔧 Need to clean up bucket names to match your project
4. 🔧 Remove all hardcoded values

## NEXT STEPS:

**Please tell me:**
1. Your actual GCP project ID
2. Confirm europe-west2 region is correct
3. Whether you have existing buckets to import

Then I can:
1. Fix all project references
2. Update bucket naming
3. Clean environment templates
4. Prepare for deployment

## EXAMPLE OF WHAT NEEDS FIXING:

Currently scattered throughout code:
```
❌ "vita-strategies" (might not be real project ID)
❌ "us-central1" (inconsistent with variables.tf)  
❌ "GCP_PROJECT_PLACEHOLDER" (placeholder values)
❌ Hardcoded bucket names
```

Should be:
```
✅ ${var.project_id} (from variables)
✅ ${var.region} (from variables)
✅ Configurable via environment variables
✅ Consistent naming patterns
```
