#!/bin/bash

# Disaster Recovery Script for Todo Application
echo "🚨 Disaster Recovery Script for Todo Application..."

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

# Function to check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}🔍 Checking Prerequisites...${NC}"
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_status "FAIL" "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're connected to a cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_status "FAIL" "Not connected to Kubernetes cluster"
        exit 1
    fi
    
    # Check if todo-app namespace exists
    if ! kubectl get namespace todo-app &> /dev/null; then
        print_status "FAIL" "todo-app namespace not found"
        exit 1
    fi
    
    print_status "PASS" "All prerequisites met"
}

# Function to list available backups
list_backups() {
    echo -e "\n${BLUE}🔍 Listing Available Backups...${NC}"
    
    # List database backups
    echo "Database Backups:"
    kubectl get jobs -n todo-app -l purpose=backup --sort-by=.metadata.creationTimestamp | grep database-backup || echo "No database backups found"
    
    # List application state backups
    echo -e "\nApplication State Backups:"
    kubectl get jobs -n todo-app -l purpose=backup --sort-by=.metadata.creationTimestamp | grep application-backup || echo "No application backups found"
    
    # List backup PVCs
    echo -e "\nBackup Storage PVCs:"
    kubectl get pvc -n todo-app -l purpose=backup || echo "No backup PVCs found"
}

# Function to restore database from backup
restore_database() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        echo -e "\n${YELLOW}📋 Available Database Backups:${NC}"
        kubectl get jobs -n todo-app -l purpose=backup --sort-by=.metadata.creationTimestamp | grep database-backup | head -5
        
        echo -e "\n${BLUE}Usage: $0 restore-db <backup-job-name>${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}🔄 Restoring Database from Backup: $backup_file${NC}"
    
    # Check if backup job exists
    if ! kubectl get job "$backup_file" -n todo-app &> /dev/null; then
        print_status "FAIL" "Backup job '$backup_file' not found"
        return 1
    fi
    
    # Create restore job
    cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: todo-database-restore-$(date +%Y%m%d-%H%M%S)
  namespace: todo-app
  labels:
    app: todo-app
    purpose: restore
    environment: development
    version: v1
spec:
  template:
    metadata:
      labels:
        app: todo-app
        purpose: restore
        environment: development
        version: v1
    spec:
      serviceAccountName: todo-backup-sa
      restartPolicy: Never
      containers:
      - name: database-restore
        image: postgres:15-alpine
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting database restore from backup..."
          
          # Find the latest backup file
          LATEST_BACKUP=\$(ls -t /backup-storage/*.sql.gz | head -1)
          
          if [ -z "\$LATEST_BACKUP" ]; then
            echo "No backup files found in /backup-storage"
            exit 1
          fi
          
          echo "Restoring from: \$LATEST_BACKUP"
          
          # Drop existing database and recreate
          psql -h todo-postgres -U postgres -c "DROP DATABASE IF EXISTS tododb;"
          psql -h todo-postgres -U postgres -c "CREATE DATABASE tododb;"
          
          # Restore from backup
          gunzip -c \$LATEST_BACKUP | psql -h todo-postgres -U postgres -d tododb
          
          echo "Database restore completed successfully"
          
          # Verify restore
          echo "Verifying restore..."
          psql -h todo-postgres -U postgres -d tododb -c "SELECT COUNT(*) as todo_count FROM todos;"
          
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
            cpu: "1"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: todo-backup-pvc
EOF
    
    print_status "PASS" "Database restore job created"
}

# Function to restore application state
restore_application_state() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        echo -e "\n${YELLOW}📋 Available Application Backups:${NC}"
        kubectl get jobs -n todo-app -l purpose=backup --sort-by=.metadata.creationTimestamp | grep application-backup | head -5
        
        echo -e "\n${BLUE}Usage: $0 restore-app <backup-job-name>${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}🔄 Restoring Application State from Backup: $backup_file${NC}"
    
    # Check if backup job exists
    if ! kubectl get job "$backup_file" -n todo-app &> /dev/null; then
        print_status "FAIL" "Backup job '$backup_file' not found"
        return 1
    fi
    
    # Create restore job
    cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: todo-app-restore-$(date +%Y%m%d-%H%M%S)
  namespace: todo-app
  labels:
    app: todo-app
    purpose: restore
    environment: development
    version: v1
spec:
  template:
    metadata:
      labels:
        app: todo-app
        purpose: restore
        environment: development
        version: v1
    spec:
      serviceAccountName: todo-backup-sa
      restartPolicy: Never
      containers:
      - name: application-restore
        image: bitnami/kubectl:latest
        command:
        - /bin/bash
        - -c
        - |
          echo "Starting application state restore from backup..."
          
          # Find the latest backup file
          LATEST_BACKUP=\$(ls -t /backup-storage/*.tar.gz | head -1)
          
          if [ -z "\$LATEST_BACKUP" ]; then
            echo "No backup files found in /backup-storage"
            exit 1
          fi
          
          echo "Restoring from: \$LATEST_BACKUP"
          
          # Extract backup
          cd /backup-storage
          tar -xzf \$LATEST_BACKUP
          
          # Find extracted directory
          BACKUP_DIR=\$(ls -d app-backup-* | head -1)
          
          if [ -z "\$BACKUP_DIR" ]; then
            echo "Could not find extracted backup directory"
            exit 1
          fi
          
          echo "Restoring from directory: \$BACKUP_DIR"
          
          # Restore resources (excluding secrets with sensitive data)
          kubectl apply -f \$BACKUP_DIR/configmaps.yaml
          kubectl apply -f \$BACKUP_DIR/deployments.yaml
          kubectl apply -f \$BACKUP_DIR/services.yaml
          kubectl apply -f \$BACKUP_DIR/network-policies.yaml
          kubectl apply -f \$BACKUP_DIR/rbac.yaml
          kubectl apply -f \$BACKUP_DIR/ingress.yaml
          
          # Clean up
          rm -rf \$BACKUP_DIR
          
          echo "Application state restore completed successfully"
          
          # Verify restore
          echo "Verifying restore..."
          kubectl get all -n todo-app
          
        env:
        - name: KUBECONFIG
          value: "/var/run/secrets/kubernetes.io/serviceaccount"
        volumeMounts:
        - name: backup-storage
          mountPath: /backup-storage
        resources:
          limits:
            cpu: "1"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: todo-backup-pvc
EOF
    
    print_status "PASS" "Application state restore job created"
}

# Function to perform full disaster recovery
full_disaster_recovery() {
    echo -e "\n${BLUE}🚨 Starting Full Disaster Recovery Process...${NC}"
    
    print_status "INFO" "This will restore both database and application state"
    print_status "INFO" "Make sure you have recent backups available"
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "INFO" "Disaster recovery cancelled"
        return 1
    fi
    
    # Step 1: Restore database
    echo -e "\n${BLUE}Step 1: Restoring Database...${NC}"
    restore_database "latest"
    
    # Step 2: Restore application state
    echo -e "\n${BLUE}Step 2: Restoring Application State...${NC}"
    restore_application_state "latest"
    
    # Step 3: Verify recovery
    echo -e "\n${BLUE}Step 3: Verifying Recovery...${NC}"
    sleep 30  # Wait for restore jobs to complete
    
    kubectl get jobs -n todo-app -l purpose=restore
    kubectl get pods -n todo-app
    
    print_status "PASS" "Full disaster recovery process initiated"
}

# Function to show recovery status
show_recovery_status() {
    echo -e "\n${BLUE}📊 Recovery Status...${NC}"
    
    echo "Restore Jobs:"
    kubectl get jobs -n todo-app -l purpose=restore --sort-by=.metadata.creationTimestamp
    
    echo -e "\nApplication Pods:"
    kubectl get pods -n todo-app
    
    echo -e "\nDatabase Status:"
    kubectl get pods -n todo-app -l app=todo-postgres
}

# Function to show help
show_help() {
    echo -e "${BLUE}🚨 Todo Application Disaster Recovery Script${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  check              - Check prerequisites and cluster status"
    echo "  list-backups       - List available backups"
    echo "  restore-db <job>   - Restore database from backup job"
    echo "  restore-app <job>  - Restore application state from backup job"
    echo "  full-recovery      - Perform complete disaster recovery"
    echo "  status             - Show recovery status"
    echo "  help               - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 list-backups"
    echo "  $0 restore-db todo-database-backup-20250827"
    echo "  $0 restore-app todo-application-backup-20250827"
    echo "  $0 full-recovery"
    echo "  $0 status"
}

# Main script logic
main() {
    case "${1:-help}" in
        "check")
            check_prerequisites
            ;;
        "list-backups")
            check_prerequisites
            list_backups
            ;;
        "restore-db")
            check_prerequisites
            restore_database "$2"
            ;;
        "restore-app")
            check_prerequisites
            restore_application_state "$2"
            ;;
        "full-recovery")
            check_prerequisites
            full_disaster_recovery
            ;;
        "status")
            check_prerequisites
            show_recovery_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
