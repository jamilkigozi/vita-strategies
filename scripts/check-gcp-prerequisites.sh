#!/bin/bash
# VITA STRATEGIES - GCP PREREQUISITES CHECK SCRIPT
# Purpose: Check if the GCP project exists and required APIs are enabled

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get project ID from terraform.tfvars
PROJECT_ID=$(grep "project_id" infrastructure/terraform/terraform.tfvars | cut -d'"' -f2)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Could not find project_id in terraform.tfvars${NC}"
    exit 1
fi

echo "🔍 VITA STRATEGIES - GCP PREREQUISITES CHECK"
echo "==========================================="
echo ""
echo "Checking GCP project and APIs for project: $PROJECT_ID"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud SDK is not installed${NC}"
    echo "Please install the Google Cloud SDK from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is logged in
GCLOUD_AUTH=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -z "$GCLOUD_AUTH" ]; then
    echo -e "${RED}❌ Not logged in to Google Cloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi
echo -e "${GREEN}✅ Logged in as: $GCLOUD_AUTH${NC}"

# Check if project exists
PROJECT_EXISTS=$(gcloud projects list --filter="PROJECT_ID=$PROJECT_ID" --format="value(PROJECT_ID)" 2>/dev/null)
if [ -z "$PROJECT_EXISTS" ]; then
    echo -e "${RED}❌ Project $PROJECT_ID does not exist${NC}"
    echo ""
    echo "Options:"
    echo "1. Create the project:"
    echo "   gcloud projects create $PROJECT_ID --name=\"Vita Strategies\""
    echo ""
    echo "2. Or update terraform.tfvars to use an existing project:"
    echo "   Available projects:"
    gcloud projects list --format="table(PROJECT_ID,NAME)"
    exit 1
fi
echo -e "${GREEN}✅ Project $PROJECT_ID exists${NC}"

# Check if required APIs are enabled
echo ""
echo "Checking required APIs:"
REQUIRED_APIS=("compute.googleapis.com" "storage.googleapis.com")

for api in "${REQUIRED_APIS[@]}"; do
    API_ENABLED=$(gcloud services list --project=$PROJECT_ID --filter="NAME:$api" --format="value(NAME)" 2>/dev/null)
    if [ -z "$API_ENABLED" ]; then
        echo -e "${RED}❌ $api is not enabled${NC}"
        print_warning "To enable, run: gcloud services enable $api --project=$PROJECT_ID"
    else
        echo -e "${GREEN}✅ $api is enabled${NC}"
    fi
done

# Check if user has required permissions
echo ""
echo "Checking permissions:"
PERMISSIONS=("compute.instances.create" "storage.buckets.create")

for permission in "${PERMISSIONS[@]}"; do
    HAS_PERMISSION=$(gcloud projects get-iam-policy $PROJECT_ID --format="json" | grep -c "$permission" || true)
    if [ "$HAS_PERMISSION" -eq 0 ]; then
        print_warning "Could not verify permission: $permission"
        print_warning "You may need to request this permission from your administrator"
    else
        echo -e "${GREEN}✅ Has permission: $permission${NC}"
    fi
done

echo ""
echo "🎉 PREREQUISITES CHECK COMPLETE"
echo "=============================="
echo ""
if [ -z "$API_ENABLED" ]; then
    echo -e "${YELLOW}⚠️  Some APIs need to be enabled before deployment${NC}"
    echo "Run the following commands to enable required APIs:"
    for api in "${REQUIRED_APIS[@]}"; do
        API_ENABLED=$(gcloud services list --project=$PROJECT_ID --filter="NAME:$api" --format="value(NAME)" 2>/dev/null)
        if [ -z "$API_ENABLED" ]; then
            echo "gcloud services enable $api --project=$PROJECT_ID"
        fi
    done
else
    echo -e "${GREEN}✅ All prerequisites are met!${NC}"
    echo "You can now proceed with deployment using:"
    echo "./scripts/deploy-safe.sh"
fi