#!/bin/bash

# Clean Deployment Script for Todo App
# This script ensures a clean deployment with proper enum values

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="development"
RELEASE_NAME="todo-app-dev"
CHART_PATH="helm/todo-app"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup_existing() {
    log_info "Cleaning up existing deployment..."
    
    # Check if Helm release exists
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        log_info "Uninstalling existing Helm release..."
        helm uninstall $RELEASE_NAME -n $NAMESPACE
    fi
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE 2>/dev/null; then
        log_info "Deleting existing namespace..."
        kubectl delete namespace $NAMESPACE
    fi
    
    log_success "Cleanup completed"
}

deploy_clean() {
    log_info "Deploying Todo app with clean configuration..."
    
    # Deploy using Helm
    helm upgrade --install $RELEASE_NAME $CHART_PATH \
        --namespace $NAMESPACE \
        --create-namespace \
        --values $CHART_PATH/values.yaml \
        --values $CHART_PATH/values-development.yaml \
        --set global.environment=development \
        --wait \
        --timeout 10m
    
    log_success "Helm deployment completed"
}

wait_for_ready() {
    log_info "Waiting for all pods to be ready..."
    
    # Wait for PostgreSQL
    kubectl wait --for=condition=ready pod -l app=todo-postgres -n ${NAMESPACE}-todo-app --timeout=300s
    
    # Wait for Backend
    kubectl wait --for=condition=ready pod -l app=todo-backend -n ${NAMESPACE}-todo-app --timeout=300s
    
    log_success "All pods are ready"
}

verify_database() {
    log_info "Verifying database schema and data..."
    
    # Wait a bit for PostgreSQL to fully initialize
    sleep 10
    
    # Check if todos table exists and has correct data
    kubectl exec -n ${NAMESPACE}-todo-app deployment/todo-app-postgres -- psql -U postgres -d tododb -c "
        SELECT 
            COUNT(*) as total_todos,
            COUNT(CASE WHEN priority IN ('LOW', 'MEDIUM', 'HIGH') THEN 1 END) as valid_priorities,
            COUNT(CASE WHEN priority NOT IN ('LOW', 'MEDIUM', 'HIGH') THEN 1 END) as invalid_priorities
        FROM todos;
    "
    
    log_success "Database verification completed"
}

test_api() {
    log_info "Testing API endpoints..."
    
    # Start port-forward
    kubectl port-forward -n ${NAMESPACE}-todo-app service/todo-app-backend 8081:8080 &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    sleep 5
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    curl -s http://localhost:8081/actuator/health | jq .status
    
    # Test todos endpoint
    log_info "Testing todos endpoint..."
    curl -s http://localhost:8081/api/todos | jq '.content | length'
    
    # Test creating a new todo
    log_info "Testing todo creation..."
    curl -X POST -H "Content-Type: application/json" \
        -d '{"title":"Test Clean Deployment","description":"This todo was created after clean deployment","priority":"HIGH"}' \
        http://localhost:8081/api/todos | jq .id
    
    # Stop port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    log_success "API testing completed"
}

show_status() {
    log_info "Final deployment status:"
    
    echo "=== Pods ==="
    kubectl get pods -n ${NAMESPACE}-todo-app
    
    echo
    echo "=== Services ==="
    kubectl get services -n ${NAMESPACE}-todo-app
    
    echo
    echo "=== Helm Release ==="
    helm status $RELEASE_NAME -n $NAMESPACE
}

main() {
    log_info "Starting clean deployment of Todo app..."
    
    cleanup_existing
    deploy_clean
    wait_for_ready
    verify_database
    test_api
    show_status
    
    log_success "Clean deployment completed successfully!"
    log_info "Your Todo app is now running with proper enum values"
    log_info "Access the API at: http://localhost:8081 (when port-forward is active)"
}

# Run main function
main "$@"
