#!/bin/bash

# Cleanup script for Vita Strategies workspace
# Created: 2025-08-05

echo "Starting workspace cleanup..."

# Remove empty files
echo "Removing empty files..."
find_empty_files=$(find . -type f -empty | grep -v "node_modules\|.git")
for file in $find_empty_files; do
  echo "Removing empty file: $file"
  rm "$file"
done

# Remove backup files
echo "Removing backup files..."
find_backup_files=$(find . -name "*.bak" -o -name "*.backup" -o -name "*.tmp" -o -name "*.temp" -o -name "*~" | grep -v "node_modules\|.git")
for file in $find_backup_files; do
  echo "Removing backup file: $file"
  rm "$file"
done

# Remove any log files if they exist
echo "Removing log files..."
find_log_files=$(find . -name "*.log" -o -name "*.swp" -o -name ".DS_Store" | grep -v "node_modules\|.git")
for file in $find_log_files; do
  echo "Removing log file: $file"
  rm "$file"
done

echo "Workspace cleanup completed successfully!"
echo "Your workspace is now clean and ready for deployment."