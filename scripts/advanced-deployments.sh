#!/bin/bash

# Advanced Deployment Strategies Management Script
echo "🚀 Advanced Deployment Strategies Management Script..."

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

# Function to show help
show_help() {
    echo -e "${BLUE}🚀 Advanced Deployment Strategies Management Script${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  deploy-blue-green    - Deploy blue-green infrastructure"
    echo "  switch-blue-green    - Switch between blue and green deployments"
    echo "  deploy-canary        - Deploy canary version"
    echo "  adjust-canary        - Adjust canary traffic weight (0-100)"
    echo "  promote-canary       - Promote canary to production"
    echo "  rollback             - Rollback to previous deployment"
    echo "  status               - Show deployment status"
    echo "  test-deployment      - Test deployment health"
    echo "  cleanup              - Clean up test deployments"
    echo "  help                 - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy-blue-green"
    echo "  $0 switch-blue-green green"
    echo "  $0 deploy-canary"
    echo "  $0 adjust-canary 25"
    echo "  $0 promote-canary"
    echo "  $0 rollback"
    echo "  $0 status"
}

# Function to deploy blue-green infrastructure
deploy_blue_green() {
    echo -e "\n${BLUE}🔵🟢 Deploying Blue-Green Infrastructure...${NC}"
    
    # Apply blue-green deployments
    kubectl apply -f k8s/base/advanced-deployments/blue-green-deployments.yaml
    kubectl apply -f k8s/base/advanced-deployments/blue-green-service.yaml
    
    # Wait for blue deployment to be ready
    echo "Waiting for blue deployment to be ready..."
    kubectl wait --for=condition=available deployment/todo-backend-blue -n todo-app --timeout=300s
    kubectl wait --for=condition=available deployment/todo-frontend-blue -n todo-app --timeout=300s
    
    print_status "PASS" "Blue-Green infrastructure deployed successfully"
    
    # Show status
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
    kubectl get services -n todo-app -l purpose=advanced-deployments
}

# Function to switch between blue and green deployments
switch_blue_green() {
    local target_version="${1:-green}"
    
    if [[ ! "$target_version" =~ ^(blue|green)$ ]]; then
        print_status "FAIL" "Invalid version. Use 'blue' or 'green'"
        return 1
    fi
    
    echo -e "\n${BLUE}🔄 Switching to ${target_version} deployment...${NC}"
    
    # Update service selectors
    if [ "$target_version" = "green" ]; then
        # Switch to green
        kubectl patch service todo-blue-green-service -n todo-app -p '{"spec":{"selector":{"version":"green"}}}'
        kubectl patch service todo-frontend-blue-green-service -n todo-app -p '{"spec":{"selector":{"version":"green"}}}'
        
        # Scale up green, scale down blue
        kubectl scale deployment todo-backend-green -n todo-app --replicas=2
        kubectl scale deployment todo-frontend-green -n todo-app --replicas=2
        kubectl scale deployment todo-backend-blue -n todo-app --replicas=0
        kubectl scale deployment todo-frontend-blue -n todo-app --replicas=0
        
        # Update annotations
        kubectl patch service todo-blue-green-service -n todo-app -p '{"metadata":{"annotations":{"blue-green.kubernetes.io/active-deployment":"green"}}}'
        kubectl patch service todo-frontend-blue-green-service -n todo-app -p '{"metadata":{"annotations":{"blue-green.kubernetes.io/active-deployment":"green"}}}'
    else
        # Switch to blue
        kubectl patch service todo-blue-green-service -n todo-app -p '{"spec":{"selector":{"version":"blue"}}}'
        kubectl patch service todo-frontend-blue-green-service -n todo-app -p '{"spec":{"selector":{"version":"blue"}}}'
        
        # Scale up blue, scale down green
        kubectl scale deployment todo-backend-blue -n todo-app --replicas=2
        kubectl scale deployment todo-frontend-blue -n todo-app --replicas=2
        kubectl scale deployment todo-backend-green -n todo-app --replicas=0
        kubectl scale deployment todo-frontend-green -n todo-app --replicas=0
        
        # Update annotations
        kubectl patch service todo-blue-green-service -n todo-app -p '{"metadata":{"annotations":{"blue-green.kubernetes.io/active-deployment":"blue"}}}'
        kubectl patch service todo-frontend-blue-green-service -n todo-app -p '{"metadata":{"annotations":{"blue-green.kubernetes.io/active-deployment":"blue"}}}'
    fi
    
    print_status "PASS" "Switched to ${target_version} deployment"
    
    # Show current status
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
}

# Function to deploy canary version
deploy_canary() {
    echo -e "\n${BLUE}🦅 Deploying Canary Version...${NC}"
    
    # Apply canary deployments
    kubectl apply -f k8s/base/advanced-deployments/canary-deployment.yaml
    
    # Wait for canary to be ready
    echo "Waiting for canary deployment to be ready..."
    kubectl wait --for=condition=available deployment/todo-backend-canary -n todo-app --timeout=300s
    kubectl wait --for=condition=available deployment/todo-frontend-canary -n todo-app --timeout=300s
    
    print_status "PASS" "Canary deployment deployed successfully"
    
    # Show status
    kubectl get deployments -n todo-app -l purpose=canary-deployment
    kubectl get services -n todo-app -l purpose=canary-deployment
}

# Function to adjust canary traffic weight
adjust_canary() {
    local weight="${1:-10}"
    
    if [[ ! "$weight" =~ ^[0-9]+$ ]] || [ "$weight" -gt 100 ]; then
        print_status "FAIL" "Invalid weight. Use 0-100"
        return 1
    fi
    
    echo -e "\n${BLUE}⚖️  Adjusting Canary Traffic Weight to ${weight}%...${NC}"
    
    # Update canary annotations
    kubectl patch deployment todo-backend-canary -n todo-app -p "{\"metadata\":{\"annotations\":{\"canary.kubernetes.io/weight\":\"${weight}\"}}}"
    kubectl patch deployment todo-frontend-canary -n todo-app -p "{\"metadata\":{\"annotations\":{\"canary.kubernetes.io/weight\":\"${weight}\"}}}"
    
    # Update service annotations
    kubectl patch service todo-canary-service -n todo-app -p "{\"metadata\":{\"annotations\":{\"canary.kubernetes.io/weight\":\"${weight}\"}}}"
    
    # Scale canary based on weight
    local canary_replicas=$((2 * weight / 100))
    if [ "$canary_replicas" -eq 0 ] && [ "$weight" -gt 0 ]; then
        canary_replicas=1
    fi
    
    kubectl scale deployment todo-backend-canary -n todo-app --replicas=$canary_replicas
    kubectl scale deployment todo-frontend-canary -n todo-app --replicas=$canary_replicas
    
    print_status "PASS" "Canary traffic weight adjusted to ${weight}%"
    
    # Show current status
    kubectl get deployments -n todo-app -l purpose=canary-deployment
}

# Function to promote canary to production
promote_canary() {
    echo -e "\n${BLUE}🚀 Promoting Canary to Production...${NC}"
    
    # Scale up canary to full production replicas
    kubectl scale deployment todo-backend-canary -n todo-app --replicas=2
    kubectl scale deployment todo-frontend-canary -n todo-app --replicas=2
    
    # Update canary phase to production
    kubectl patch deployment todo-backend-canary -n todo-app -p '{"metadata":{"annotations":{"canary.kubernetes.io/phase":"production"}}}'
    kubectl patch deployment todo-frontend-canary -n todo-app -p '{"metadata":{"annotations":{"canary.kubernetes.io/phase":"production"}}}'
    
    # Update service annotations
    kubectl patch service todo-canary-service -n todo-app -p '{"metadata":{"annotations":{"canary.kubernetes.io/phase":"production"}}}'
    
    print_status "PASS" "Canary promoted to production"
    
    # Show current status
    kubectl get deployments -n todo-app -l purpose=canary-deployment
}

# Function to rollback deployment
rollback() {
    local deployment_name="${1:-todo-backend}"
    
    echo -e "\n${BLUE}🔄 Rolling back ${deployment_name}...${NC}"
    
    # Get current revision
    local current_revision=$(kubectl rollout history deployment/$deployment_name -n todo-app --no-headers | head -1 | awk '{print $1}')
    
    if [ -z "$current_revision" ]; then
        print_status "FAIL" "No deployment history found for $deployment_name"
        return 1
    fi
    
    # Get previous revision
    local previous_revision=$(kubectl rollout history deployment/$deployment_name -n todo-app --no-headers | head -2 | tail -1 | awk '{print $1}')
    
    if [ -z "$previous_revision" ]; then
        print_status "FAIL" "No previous revision found for $deployment_name"
        return 1
    fi
    
    echo "Current revision: $current_revision"
    echo "Rolling back to revision: $previous_revision"
    
    # Perform rollback
    kubectl rollout undo deployment/$deployment_name -n todo-app --to-revision=$previous_revision
    
    # Wait for rollback to complete
    kubectl rollout status deployment/$deployment_name -n todo-app --timeout=300s
    
    if [ $? -eq 0 ]; then
        print_status "PASS" "Rollback completed successfully"
    else
        print_status "FAIL" "Rollback failed"
        return 1
    fi
}

# Function to show deployment status
show_status() {
    echo -e "\n${BLUE}📊 Deployment Status...${NC}"
    
    echo "Blue-Green Deployments:"
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
    echo -e "\nBlue-Green Services:"
    kubectl get services -n todo-app -l purpose=advanced-deployments
    
    echo -e "\nCanary Deployments:"
    kubectl get deployments -n todo-app -l purpose=canary-deployment
    echo -e "\nCanary Services:"
    kubectl get services -n todo-app -l purpose=canary-deployment
    
    echo -e "\nRollback Deployments:"
    kubectl get deployments -n todo-app -l purpose=rollback-strategy
    echo -e "\nRollback Services:"
    kubectl get services -n todo-app -l purpose=rollback-strategy
    
    echo -e "\nAll Pods:"
    kubectl get pods -n todo-app -l app=todo-backend --sort-by=.metadata.creationTimestamp
}

# Function to test deployment health
test_deployment() {
    echo -e "\n${BLUE}🧪 Testing Deployment Health...${NC}"
    
    # Test blue-green service
    if kubectl get service todo-blue-green-service -n todo-app &> /dev/null; then
        local bg_endpoint=$(kubectl get service todo-blue-green-service -n todo-app -o jsonpath='{.spec.clusterIP}')
        echo "Testing Blue-Green Service at $bg_endpoint:8080"
        kubectl run test-bg-health --image=curlimages/curl -n todo-app --rm -it --restart=Never -- curl -s "http://$bg_endpoint:8080/actuator/health" || echo "Health check failed"
    fi
    
    # Test canary service
    if kubectl get service todo-canary-service -n todo-app &> /dev/null; then
        local canary_endpoint=$(kubectl get service todo-canary-service -n todo-app -o jsonpath='{.spec.clusterIP}')
        echo "Testing Canary Service at $canary_endpoint:8080"
        kubectl run test-canary-health --image=curlimages/curl -n todo-app --rm -it --restart=Never -- curl -s "http://$canary_endpoint:8080/actuator/health" || echo "Health check failed"
    fi
    
    print_status "PASS" "Deployment health tests completed"
}

# Function to cleanup test deployments
cleanup() {
    echo -e "\n${BLUE}🧹 Cleaning up test deployments...${NC}"
    
    # Delete advanced deployment resources
    kubectl delete -f k8s/base/advanced-deployments/blue-green-deployments.yaml --ignore-not-found=true
    kubectl delete -f k8s/base/advanced-deployments/blue-green-service.yaml --ignore-not-found=true
    kubectl delete -f k8s/base/advanced-deployments/canary-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/base/advanced-deployments/rollback-strategy.yaml --ignore-not-found=true
    
    # Clean up any test pods
    kubectl delete pod -n todo-app -l run=test-bg-health --ignore-not-found=true
    kubectl delete pod -n todo-app -l run=test-canary-health --ignore-not-found=true
    
    print_status "PASS" "Cleanup completed"
}

# Main script logic
main() {
    case "${1:-help}" in
        "deploy-blue-green")
            deploy_blue_green
            ;;
        "switch-blue-green")
            switch_blue_green "$2"
            ;;
        "deploy-canary")
            deploy_canary
            ;;
        "adjust-canary")
            adjust_canary "$2"
            ;;
        "promote-canary")
            promote_canary
            ;;
        "rollback")
            rollback "$2"
            ;;
        "status")
            show_status
            ;;
        "test-deployment")
            test_deployment
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
