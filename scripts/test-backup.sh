#!/bin/bash

# Test Backup & Disaster Recovery Implementation
echo "🧪 Testing Backup & Disaster Recovery Implementation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
    else
        echo -e "${BLUE}ℹ️  INFO${NC}: $message"
    fi
}

# Function to test backup infrastructure
test_backup_infrastructure() {
    echo -e "\n${BLUE}🔍 Testing Backup Infrastructure...${NC}"
    
    # Check if backup PVCs exist
    local backup_pvc_count=$(kubectl get pvc -n todo-app -l purpose=backup --no-headers | wc -l)
    if [ "$backup_pvc_count" -ge 1 ]; then
        print_status "PASS" "Backup PVCs created: $backup_pvc_count"
    else
        print_status "FAIL" "Expected 1+ backup PVCs, found: $backup_pvc_count"
    fi
    
    # Check if backup service account exists
    if kubectl get serviceaccount todo-backup-sa -n todo-app &> /dev/null; then
        print_status "PASS" "Backup service account exists"
    else
        print_status "FAIL" "Backup service account not found"
    fi
    
    # Check if backup RBAC exists
    local backup_role_count=$(kubectl get roles -n todo-app -l purpose=backup --no-headers | wc -l)
    if [ "$backup_role_count" -ge 1 ]; then
        print_status "PASS" "Backup roles created: $backup_role_count"
    else
        print_status "FAIL" "Expected 1+ backup roles, found: $backup_role_count"
    fi
    
    # List backup infrastructure
    echo "Backup PVCs:"
    kubectl get pvc -n todo-app -l purpose=backup
    echo -e "\nBackup Service Account:"
    kubectl get serviceaccount todo-backup-sa -n todo-app
    echo -e "\nBackup RBAC:"
    kubectl get roles,rolebindings -n todo-app -l purpose=backup
}

# Function to test backup jobs
test_backup_jobs() {
    echo -e "\n${BLUE}🔍 Testing Backup Jobs...${NC}"
    
    # Check if database backup cronjob exists
    if kubectl get cronjob todo-database-backup -n todo-app &> /dev/null; then
        print_status "PASS" "Database backup CronJob exists"
    else
        print_status "FAIL" "Database backup CronJob not found"
    fi
    
    # Check if application backup cronjob exists
    if kubectl get cronjob todo-application-backup-scheduled -n todo-app &> /dev/null; then
        print_status "PASS" "Application backup CronJob exists"
    else
        print_status "FAIL" "Application backup CronJob not found"
    fi
    
    # List backup jobs
    echo "Backup CronJobs:"
    kubectl get cronjobs -n todo-app -l purpose=backup
}

# Function to test manual backup execution
test_manual_backup() {
    echo -e "\n${BLUE}🔍 Testing Manual Backup Execution...${NC}"
    
    print_status "INFO" "Creating manual database backup..."
    
    # Create a manual database backup job
    cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: todo-manual-db-backup-test
  namespace: todo-app
  labels:
    app: todo-app
    purpose: backup
    test: manual
    environment: development
    version: v1
spec:
  template:
    metadata:
      labels:
        app: todo-app
        purpose: backup
        test: manual
        environment: development
        version: v1
    spec:
      serviceAccountName: todo-backup-sa
      restartPolicy: Never
      containers:
      - name: database-backup
        image: postgres:15-alpine
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting manual database backup test at \$(date)"
          
          # Set timestamp for backup file
          TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
          BACKUP_FILE="tododb_manual_test_${TIMESTAMP}.sql"
          
          # Create backup directory
          mkdir -p /backups
          
          # Perform database backup
          pg_dump -h todo-postgres -U postgres -d tododb > /backups/\${BACKUP_FILE}
          
          # Compress backup
          gzip /backups/\${BACKUP_FILE}
          
          # Copy to persistent backup storage
          cp /backups/\${BACKUP_FILE}.gz /backup-storage/
          
          # Clean up local files
          rm -rf /backups
          
          echo "Manual database backup test completed: \${BACKUP_FILE}.gz"
          echo "Backup size: \$(du -h /backup-storage/\${BACKUP_FILE}.gz | cut -f1)"
          
          # Verify backup integrity
          echo "Verifying backup integrity..."
          gunzip -c /backup-storage/\${BACKUP_FILE}.gz | head -n 5
          
          echo "Manual backup test completed successfully"
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: todo-secrets
              key: db.password
        - name: PGPORT
          value: "5432"
        - name: PGDATABASE
          value: "tododb"
        - name: PGUSER
          value: "postgres"
        - name: PGHOST
          value: "todo-postgres"
        volumeMounts:
        - name: backup-storage
          mountPath: /backup-storage
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "250m"
            memory: "256Mi"
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: todo-backup-pvc
EOF
    
    if [ $? -eq 0 ]; then
        print_status "PASS" "Manual backup job created successfully"
        
        # Wait for job to complete
        echo "Waiting for backup job to complete..."
        kubectl wait --for=condition=complete job/todo-manual-db-backup-test -n todo-app --timeout=300s
        
        if [ $? -eq 0 ]; then
            print_status "PASS" "Manual backup job completed successfully"
            
            # Check backup logs
            echo "Backup job logs:"
            kubectl logs job/todo-manual-db-backup-test -n todo-app | tail -10
        else
            print_status "FAIL" "Manual backup job failed or timed out"
        fi
    else
        print_status "FAIL" "Failed to create manual backup job"
    fi
}

# Function to test backup storage
test_backup_storage() {
    echo -e "\n${BLUE}🔍 Testing Backup Storage...${NC}"
    
    # Check backup storage PVC status
    local backup_pvc_status=$(kubectl get pvc todo-backup-pvc -n todo-app -o jsonpath='{.status.phase}')
    if [ "$backup_pvc_status" = "Bound" ]; then
        print_status "PASS" "Backup storage PVC is bound"
    else
        print_status "FAIL" "Backup storage PVC status: $backup_pvc_status"
    fi
    
    # Check backup storage capacity
    local backup_storage_capacity=$(kubectl get pvc todo-backup-pvc -n todo-app -o jsonpath='{.spec.resources.requests.storage}')
    if [ "$backup_storage_capacity" = "10Gi" ]; then
        print_status "PASS" "Backup storage capacity: $backup_storage_capacity"
    else
        print_status "FAIL" "Expected 10Gi backup storage, found: $backup_storage_capacity"
    fi
    
    # List backup storage details
    echo "Backup Storage Details:"
    kubectl get pvc todo-backup-pvc -n todo-app -o wide
}

# Function to test disaster recovery script
test_disaster_recovery_script() {
    echo -e "\n${BLUE}🔍 Testing Disaster Recovery Script...${NC}"
    
    # Check if disaster recovery script exists and is executable
    if [ -x "scripts/disaster-recovery.sh" ]; then
        print_status "PASS" "Disaster recovery script exists and is executable"
    else
        print_status "FAIL" "Disaster recovery script not found or not executable"
    fi
    
    # Test script help
    local help_output=$(./scripts/disaster-recovery.sh help 2>&1)
    if echo "$help_output" | grep -q "Todo Application Disaster Recovery Script"; then
        print_status "PASS" "Disaster recovery script help works"
    else
        print_status "FAIL" "Disaster recovery script help not working"
    fi
    
    # Test script check command
    local check_output=$(./scripts/disaster-recovery.sh check 2>&1)
    if echo "$check_output" | grep -q "All prerequisites met"; then
        print_status "PASS" "Disaster recovery script check command works"
    else
        print_status "FAIL" "Disaster recovery script check command not working"
    fi
    
    echo "Disaster Recovery Script Test Output:"
    echo "$check_output" | head -10
}

# Function to test backup scheduling
test_backup_scheduling() {
    echo -e "\n${BLUE}🔍 Testing Backup Scheduling...${NC}"
    
    # Check database backup schedule
    local db_schedule=$(kubectl get cronjob todo-database-backup -n todo-app -o jsonpath='{.spec.schedule}')
    if [ "$db_schedule" = "0 2 * * *" ]; then
        print_status "PASS" "Database backup schedule: $db_schedule (Daily at 2 AM)"
    else
        print_status "FAIL" "Expected schedule '0 2 * * *', found: $db_schedule"
    fi
    
    # Check application backup schedule
    local app_schedule=$(kubectl get cronjob todo-application-backup-scheduled -n todo-app -o jsonpath='{.spec.schedule}')
    if [ "$app_schedule" = "0 3 * * *" ]; then
        print_status "PASS" "Application backup schedule: $app_schedule (Daily at 3 AM)"
    else
        print_status "FAIL" "Expected schedule '0 3 * * *', found: $app_schedule"
    fi
    
    # Check job history limits
    local db_history_limit=$(kubectl get cronjob todo-database-backup -n todo-app -o jsonpath='{.spec.successfulJobsHistoryLimit}')
    if [ "$db_history_limit" = "7" ]; then
        print_status "PASS" "Database backup history limit: $db_history_limit"
    else
        print_status "FAIL" "Expected history limit 7, found: $db_history_limit"
    fi
    
    echo "Backup Schedules:"
    kubectl get cronjobs -n todo-app -l purpose=backup -o custom-columns="NAME:.metadata.name,SCHEDULE:.spec.schedule,HISTORY:.spec.successfulJobsHistoryLimit"
}

# Function to test backup security
test_backup_security() {
    echo -e "\n${BLUE}🔍 Testing Backup Security...${NC}"
    
    # Check if backup service account has minimal permissions
    local backup_sa_permissions=$(kubectl auth can-i get secrets --as=system:serviceaccount:todo-app:todo-backup-sa -n todo-app 2>&1)
    if echo "$backup_sa_permissions" | grep -q "yes"; then
        print_status "PASS" "Backup service account can access required secrets"
    else
        print_status "FAIL" "Backup service account cannot access required secrets"
    fi
    
    # Check if backup service account cannot access other resources
    local backup_sa_restricted=$(kubectl auth can-i get pods --as=system:serviceaccount:todo-app:todo-backup-sa -n todo-app 2>&1)
    if echo "$backup_sa_restricted" | grep -q "no"; then
        print_status "PASS" "Backup service account properly restricted (cannot access pods)"
    else
        print_status "FAIL" "Backup service account has excessive permissions"
    fi
    
    # Check backup RBAC configuration
    echo "Backup RBAC Configuration:"
    kubectl get role todo-backup-role -n todo-app -o yaml | grep -A 20 "rules:"
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting Backup & Disaster Recovery Tests...${NC}"
    
    # Check if we're in the right context
    local current_context=$(kubectl config current-context)
    echo "Current Kubernetes context: $current_context"
    
    # Check if todo-app namespace exists
    if ! kubectl get namespace todo-app >/dev/null 2>&1; then
        print_status "FAIL" "todo-app namespace not found. Please deploy the application first."
        exit 1
    fi
    
    # Run all tests
    test_backup_infrastructure
    test_backup_jobs
    test_backup_storage
    test_disaster_recovery_script
    test_backup_scheduling
    test_backup_security
    
    # Test manual backup (this creates actual backup)
    test_manual_backup
    
    echo -e "\n${GREEN}🎉 Backup & Disaster Recovery Testing Complete!${NC}"
    echo -e "\n${YELLOW}📋 Summary:${NC}"
    echo "- Backup Infrastructure: PVCs, Service Accounts, RBAC"
    echo "- Backup Jobs: CronJobs for database and application state"
    echo "- Backup Storage: Persistent storage for backups"
    echo "- Disaster Recovery: Automated recovery scripts"
    echo "- Backup Scheduling: Automated daily backups"
    echo "- Backup Security: Minimal required permissions"
    echo ""
    echo "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Monitor backup jobs: kubectl get cronjobs -n todo-app"
    echo "2. Check backup storage: kubectl get pvc -n todo-app -l purpose=backup"
    echo "3. Test disaster recovery: ./scripts/disaster-recovery.sh help"
    echo "4. View backup logs: kubectl logs -n todo-app -l purpose=backup"
}

# Run main function
main "$@"
