#!/bin/bash

# =============================================================================
# VITA STRATEGIES - PRODUCTION MONITORING
# =============================================================================
# Monitor production services and send alerts
# =============================================================================

set -e

ALERT_EMAIL="jamil.kigozi@hotmail.com"
VM_NAME="vita-strategies-server"
ZONE="europe-west2-a"
SERVICES=("erpnext" "metabase" "grafana" "appsmith" "keycloak" "mattermost" "windmill")

echo "📊 VITA STRATEGIES PRODUCTION MONITORING"
echo "========================================"
echo "📅 Monitor Time: $(date)"
echo ""

# =============================================================================
# VM HEALTH CHECK
# =============================================================================

echo "🖥️  VM Health Check"
echo "=================="

# Check if VM is running
vm_status=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(status)" 2>/dev/null || echo "NOT_FOUND")

if [[ "$vm_status" == "RUNNING" ]]; then
    echo "✅ VM Status: RUNNING"
    
    # Get VM metrics
    vm_ip=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    echo "📍 VM IP: $vm_ip"
    
    # Check VM connectivity
    if ping -c 1 "$vm_ip" &> /dev/null; then
        echo "✅ VM Connectivity: OK"
    else
        echo "❌ VM Connectivity: FAILED"
        echo "🚨 ALERT: VM not reachable!"
    fi
else
    echo "❌ VM Status: $vm_status"
    echo "🚨 CRITICAL ALERT: VM is not running!"
fi
echo ""

# =============================================================================
# SERVICE HEALTH CHECK
# =============================================================================

echo "🐳 Service Health Check"
echo "======================"

if [[ "$vm_status" == "RUNNING" ]]; then
    # SSH to VM and check services
    service_status=$(gcloud compute ssh ubuntu@$VM_NAME --zone=$ZONE --command="
        cd /opt/vita-strategies 2>/dev/null || cd /home/ubuntu
        if [[ -f docker-compose.yml ]] || [[ -f docker-compose-persistent.yml ]]; then
            docker-compose ps --format 'table {{.Name}}\t{{.State}}\t{{.Ports}}'
        else
            echo 'Docker Compose not found'
        fi
    " 2>/dev/null || echo "SSH_FAILED")
    
    if [[ "$service_status" != "SSH_FAILED" ]]; then
        echo "$service_status"
        
        # Count running services
        running_services=$(echo "$service_status" | grep -c "Up" || echo "0")
        total_services=$(echo "$service_status" | wc -l | tr -d ' ')
        total_services=$((total_services - 1)) # Subtract header
        
        echo ""
        echo "📊 Service Summary: $running_services/$total_services services running"
        
        if [[ $running_services -lt $total_services ]]; then
            echo "⚠️  Some services are down!"
        fi
    else
        echo "❌ Cannot check services (SSH failed)"
    fi
else
    echo "❌ Cannot check services (VM not running)"
fi
echo ""

# =============================================================================
# WEB SERVICE CONNECTIVITY
# =============================================================================

echo "🌐 Web Service Connectivity"
echo "=========================="

if [[ "$vm_status" == "RUNNING" && -n "$vm_ip" ]]; then
    ports=("8000:ERPNext" "3000:Metabase" "3001:Grafana" "8080:Appsmith" "8090:Keycloak" "8065:Mattermost")
    
    for port_info in "${ports[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        
        # Test HTTP connectivity
        response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://$vm_ip:$port" 2>/dev/null || echo "TIMEOUT")
        
        if [[ "$response" =~ ^[2-4][0-9][0-9]$ ]]; then
            echo "✅ $service (port $port): HTTP $response"
        else
            echo "❌ $service (port $port): $response"
        fi
    done
else
    echo "❌ Cannot test web services (VM not accessible)"
fi
echo ""

# =============================================================================
# STORAGE BUCKET HEALTH
# =============================================================================

echo "📦 Storage Bucket Health"
echo "======================="

buckets=("vita-strategies-data-backup-production" "vita-strategies-erpnext-production" "vita-strategies-analytics-production")

for bucket in "${buckets[@]}"; do
    if gsutil ls "gs://$bucket" &> /dev/null; then
        file_count=$(gsutil ls "gs://$bucket/**" 2>/dev/null | wc -l | tr -d ' ')
        size=$(gsutil du -s "gs://$bucket" 2>/dev/null | awk '{print $1}' || echo "0")
        echo "✅ $bucket: $file_count files, $size bytes"
    else
        echo "❌ $bucket: Not accessible"
    fi
done
echo ""

# =============================================================================
# BACKUP STATUS CHECK
# =============================================================================

echo "💾 Backup Status"
echo "==============="

# Check latest backup in main backup bucket
latest_backup=$(gsutil ls -l "gs://vita-strategies-data-backup-production/" 2>/dev/null | tail -n +2 | tail -1 | awk '{print $2}' || echo "No backups found")

if [[ "$latest_backup" != "No backups found" ]]; then
    echo "✅ Latest backup: $latest_backup"
    
    # Check if backup is recent (within 24 hours)
    backup_time=$(gsutil ls -l "gs://vita-strategies-data-backup-production/" 2>/dev/null | tail -1 | awk '{print $2}')
    current_time=$(date -u +%s)
    backup_timestamp=$(date -d "$backup_time" +%s 2>/dev/null || echo "0")
    time_diff=$((current_time - backup_timestamp))
    hours_old=$((time_diff / 3600))
    
    if [[ $hours_old -lt 24 ]]; then
        echo "✅ Backup freshness: $hours_old hours old (OK)"
    else
        echo "⚠️  Backup freshness: $hours_old hours old (STALE)"
        echo "🚨 ALERT: Backups are stale!"
    fi
else
    echo "❌ No backups found"
    echo "🚨 CRITICAL ALERT: No backups available!"
fi
echo ""

# =============================================================================
# RESOURCE USAGE CHECK
# =============================================================================

echo "💻 Resource Usage"
echo "================"

if [[ "$vm_status" == "RUNNING" ]]; then
    # Get resource usage from VM
    resource_info=$(gcloud compute ssh ubuntu@$VM_NAME --zone=$ZONE --command="
        echo 'CPU Usage:'
        top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1
        echo 'Memory Usage:'
        free | grep Mem | awk '{printf \"%.1f%%\", \$3/\$2 * 100.0}'
        echo
        echo 'Disk Usage:'
        df -h / | tail -1 | awk '{print \$5}'
    " 2>/dev/null || echo "Cannot retrieve resource info")
    
    echo "$resource_info"
else
    echo "❌ Cannot check resources (VM not running)"
fi
echo ""

# =============================================================================
# MONITORING SUMMARY
# =============================================================================

echo "📋 MONITORING SUMMARY"
echo "===================="

# Calculate overall health score
score=0
total_checks=10

# VM running
[[ "$vm_status" == "RUNNING" ]] && score=$((score + 2))

# VM reachable
ping -c 1 "$vm_ip" &> /dev/null && score=$((score + 1))

# Services check (simplified)
[[ "$service_status" != "SSH_FAILED" ]] && score=$((score + 2))

# Web services (simplified check)
curl -s --connect-timeout 5 "http://$vm_ip:8000" &> /dev/null && score=$((score + 2))

# Buckets accessible
gsutil ls "gs://vita-strategies-data-backup-production" &> /dev/null && score=$((score + 1))

# Recent backup
[[ "$latest_backup" != "No backups found" ]] && score=$((score + 2))

health_percentage=$((score * 100 / total_checks))

echo "🏆 Overall Health Score: $health_percentage%"
echo ""

if [[ $health_percentage -ge 90 ]]; then
    echo "🎉 EXCELLENT - All systems operational"
    status_emoji="🟢"
elif [[ $health_percentage -ge 70 ]]; then
    echo "✅ GOOD - Minor issues detected"
    status_emoji="🟡"
elif [[ $health_percentage -ge 50 ]]; then
    echo "⚠️  WARNING - Several issues need attention"
    status_emoji="🟠"
else
    echo "🚨 CRITICAL - Major issues detected"
    status_emoji="🔴"
fi

echo ""
echo "$status_emoji VITA STRATEGIES PLATFORM STATUS: $health_percentage%"
echo "📅 Last checked: $(date)"
echo ""

# =============================================================================
# ALERT GENERATION
# =============================================================================

if [[ $health_percentage -lt 70 ]]; then
    echo "📧 Generating alert for low health score..."
    
    # Log alert (in production, this would send email/SMS)
    echo "$(date): ALERT - Platform health at $health_percentage%" >> /tmp/vita-strategies-alerts.log
    
    echo "⚠️  Alert logged. In production, this would:"
    echo "   • Send email to $ALERT_EMAIL"
    echo "   • Send SMS notification"
    echo "   • Post to Slack/Teams"
    echo "   • Create support ticket"
fi

echo ""
echo "🔍 Monitoring complete!"

# =============================================================================
# AUTOMATED ACTIONS (OPTIONAL)
# =============================================================================

if [[ "${1:-}" == "--auto-fix" ]]; then
    echo ""
    echo "🔧 AUTO-FIX MODE ENABLED"
    echo "======================="
    
    if [[ "$vm_status" != "RUNNING" ]]; then
        echo "🚀 Starting VM..."
        gcloud compute instances start $VM_NAME --zone=$ZONE
        echo "✅ VM start command sent"
    fi
    
    if [[ $running_services -lt $total_services ]]; then
        echo "🐳 Restarting services..."
        gcloud compute ssh ubuntu@$VM_NAME --zone=$ZONE --command="
            cd /opt/vita-strategies || cd /home/ubuntu
            docker-compose restart
        "
        echo "✅ Service restart command sent"
    fi
fi
