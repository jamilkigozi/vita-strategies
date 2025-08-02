#!/bin/bash

# =============================================================================
# VITA STRATEGIES - BUCKET MANAGEMENT TOOL
# =============================================================================
# Easy GUI access to your business data in Google Cloud Storage
# =============================================================================

ENVIRONMENT="${ENVIRONMENT:-production}"
PROJECT_ID="vita-strategies"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}🗂️  VITA STRATEGIES BUCKET MANAGER${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

show_menu() {
    echo ""
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo "1. 🌐 Open bucket GUIs in browser"
    echo "2. 📊 View ERPNext data"
    echo "3. 📈 View analytics data"
    echo "4. 👥 View team files"
    echo "5. 📦 View all assets"
    echo "6. ⬇️  Download latest backups"
    echo "7. ⬆️  Upload files to buckets"
    echo "8. 🔄 Sync Docker volumes to buckets"
    echo "9. 📋 Show bucket status"
    echo "0. 🚪 Exit"
    echo ""
}

open_browser_guis() {
    echo -e "${GREEN}🌐 Opening bucket GUIs...${NC}"
    
    BASE_URL="https://console.cloud.google.com/storage/browser"
    
    echo "Opening these URLs in your default browser:"
    echo "• ERPNext Data: $BASE_URL/vita-strategies-erpnext-$ENVIRONMENT"
    echo "• Analytics: $BASE_URL/vita-strategies-analytics-$ENVIRONMENT"
    echo "• Team Files: $BASE_URL/vita-strategies-team-files-$ENVIRONMENT"
    echo "• Assets: $BASE_URL/vita-strategies-assets-$ENVIRONMENT"
    echo "• Backups: $BASE_URL/vita-strategies-data-backup-$ENVIRONMENT"
    
    # Open URLs (works on macOS, Linux with xdg-open, Windows with start)
    if command -v open &> /dev/null; then
        # macOS
        open "$BASE_URL/vita-strategies-erpnext-$ENVIRONMENT"
        open "$BASE_URL/vita-strategies-analytics-$ENVIRONMENT"
        open "$BASE_URL/vita-strategies-team-files-$ENVIRONMENT"
        open "$BASE_URL/vita-strategies-assets-$ENVIRONMENT"
        open "$BASE_URL/vita-strategies-data-backup-$ENVIRONMENT"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$BASE_URL/vita-strategies-erpnext-$ENVIRONMENT"
        xdg-open "$BASE_URL/vita-strategies-analytics-$ENVIRONMENT"
        xdg-open "$BASE_URL/vita-strategies-team-files-$ENVIRONMENT"
        xdg-open "$BASE_URL/vita-strategies-assets-$ENVIRONMENT"
        xdg-open "$BASE_URL/vita-strategies-data-backup-$ENVIRONMENT"
    else
        echo "Please manually open the URLs above in your browser"
    fi
}

view_erpnext_data() {
    echo -e "${GREEN}📊 ERPNext Business Data:${NC}"
    echo ""
    gsutil ls -l gs://vita-strategies-erpnext-$ENVIRONMENT/ | head -20
    echo ""
    echo "💡 To access in GUI: https://console.cloud.google.com/storage/browser/vita-strategies-erpnext-$ENVIRONMENT"
}

view_analytics_data() {
    echo -e "${GREEN}📈 Analytics Data (Metabase & Grafana):${NC}"
    echo ""
    gsutil ls -l gs://vita-strategies-analytics-$ENVIRONMENT/ | head -20
    echo ""
    echo "💡 To access in GUI: https://console.cloud.google.com/storage/browser/vita-strategies-analytics-$ENVIRONMENT"
}

view_team_files() {
    echo -e "${GREEN}👥 Team Files (Mattermost):${NC}"
    echo ""
    gsutil ls -l gs://vita-strategies-team-files-$ENVIRONMENT/ | head -20
    echo ""
    echo "💡 To access in GUI: https://console.cloud.google.com/storage/browser/vita-strategies-team-files-$ENVIRONMENT"
}

view_assets() {
    echo -e "${GREEN}📦 Application Assets:${NC}"
    echo ""
    gsutil ls -l gs://vita-strategies-assets-$ENVIRONMENT/ | head -20
    echo ""
    echo "💡 To access in GUI: https://console.cloud.google.com/storage/browser/vita-strategies-assets-$ENVIRONMENT"
}

download_backups() {
    echo -e "${GREEN}⬇️  Downloading latest backups...${NC}"
    
    mkdir -p ./downloads
    
    echo "Downloading ERPNext database backup..."
    gsutil cp "gs://vita-strategies-erpnext-$ENVIRONMENT/database/$(gsutil ls gs://vita-strategies-erpnext-$ENVIRONMENT/database/ | tail -1)" ./downloads/
    
    echo "Downloading analytics backup..."
    gsutil cp "gs://vita-strategies-analytics-$ENVIRONMENT/$(gsutil ls gs://vita-strategies-analytics-$ENVIRONMENT/ | grep metabase | tail -1)" ./downloads/
    
    echo -e "${GREEN}✅ Downloads completed in ./downloads/${NC}"
    ls -la ./downloads/
}

upload_files() {
    echo -e "${YELLOW}⬆️  Upload Files to Buckets${NC}"
    echo ""
    echo "Which bucket would you like to upload to?"
    echo "1. ERPNext data"
    echo "2. Analytics data"
    echo "3. Team files"
    echo "4. Assets"
    
    read -p "Choice (1-4): " bucket_choice
    read -p "File path to upload: " file_path
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return
    fi
    
    case $bucket_choice in
        1) gsutil cp "$file_path" gs://vita-strategies-erpnext-$ENVIRONMENT/ ;;
        2) gsutil cp "$file_path" gs://vita-strategies-analytics-$ENVIRONMENT/ ;;
        3) gsutil cp "$file_path" gs://vita-strategies-team-files-$ENVIRONMENT/ ;;
        4) gsutil cp "$file_path" gs://vita-strategies-assets-$ENVIRONMENT/ ;;
        *) echo -e "${RED}❌ Invalid choice${NC}" ;;
    esac
    
    echo -e "${GREEN}✅ File uploaded successfully${NC}"
}

sync_volumes() {
    echo -e "${GREEN}🔄 Syncing Docker volumes to buckets...${NC}"
    
    if [[ -f "/opt/vita-strategies/sync-buckets.sh" ]]; then
        /opt/vita-strategies/sync-buckets.sh
    else
        echo -e "${YELLOW}⚠️  This command should be run on the VM${NC}"
        echo "SSH to VM and run: /opt/vita-strategies/sync-buckets.sh"
    fi
}

show_status() {
    echo -e "${GREEN}📋 Bucket Status:${NC}"
    echo ""
    
    buckets=(
        "vita-strategies-data-backup-$ENVIRONMENT"
        "vita-strategies-erpnext-$ENVIRONMENT"
        "vita-strategies-analytics-$ENVIRONMENT"
        "vita-strategies-team-files-$ENVIRONMENT"
        "vita-strategies-assets-$ENVIRONMENT"
    )
    
    for bucket in "${buckets[@]}"; do
        echo "📦 $bucket:"
        size=$(gsutil du -s gs://$bucket | awk '{print $1}')
        files=$(gsutil ls gs://$bucket | wc -l)
        echo "   Size: $size bytes"
        echo "   Files: $files"
        echo ""
    done
}

# Main loop
while true; do
    print_header
    show_menu
    
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1) open_browser_guis ;;
        2) view_erpnext_data ;;
        3) view_analytics_data ;;
        4) view_team_files ;;
        5) view_assets ;;
        6) download_backups ;;
        7) upload_files ;;
        8) sync_volumes ;;
        9) show_status ;;
        0) 
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
