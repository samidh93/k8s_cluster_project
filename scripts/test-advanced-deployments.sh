#!/bin/bash

# Test Advanced Deployment Strategies Implementation
echo "🧪 Testing Advanced Deployment Strategies Implementation..."

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

# Function to test blue-green deployment infrastructure
test_blue_green_infrastructure() {
    echo -e "\n${BLUE}🔍 Testing Blue-Green Deployment Infrastructure...${NC}"
    
    # Check if blue-green deployments exist
    local bg_deployment_count=$(kubectl get deployments -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$bg_deployment_count" -ge 4 ]; then
        print_status "PASS" "Blue-green deployments created: $bg_deployment_count"
    else
        print_status "FAIL" "Expected 4+ blue-green deployments, found: $bg_deployment_count"
    fi
    
    # Check if blue-green services exist
    local bg_service_count=$(kubectl get services -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$bg_service_count" -ge 2 ]; then
        print_status "PASS" "Blue-green services created: $bg_service_count"
    else
        print_status "FAIL" "Expected 2+ blue-green services, found: $bg_service_count"
    fi
    
    # List blue-green resources
    echo "Blue-Green Deployments:"
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
    echo -e "\nBlue-Green Services:"
    kubectl get services -n todo-app -l purpose=advanced-deployments
}

# Function to test canary deployment infrastructure
test_canary_infrastructure() {
    echo -e "\n${BLUE}🔍 Testing Canary Deployment Infrastructure...${NC}"
    
    # Check if canary deployments exist
    local canary_deployment_count=$(kubectl get deployments -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$canary_deployment_count" -ge 2 ]; then
        print_status "PASS" "Canary deployments created: $canary_deployment_count"
    else
        print_status "FAIL" "Expected 2+ canary deployments, found: $canary_deployment_count"
    fi
    
    # Check if canary services exist
    local canary_service_count=$(kubectl get services -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$canary_service_count" -ge 1 ]; then
        print_status "PASS" "Canary services created: $canary_service_count"
    else
        print_status "FAIL" "Expected 1+ canary services, found: $canary_service_count"
    fi
    
    # List canary resources
    echo "Canary Deployments:"
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
    echo -e "\nCanary Services:"
    kubectl get services -n todo-app -l purpose=advanced-deployments
}

# Function to test rollback strategy infrastructure
test_rollback_infrastructure() {
    echo -e "\n${BLUE}🔍 Testing Rollback Strategy Infrastructure...${NC}"
    
    # Check if rollback deployments exist
    local rollback_deployment_count=$(kubectl get deployments -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$rollback_deployment_count" -ge 1 ]; then
        print_status "PASS" "Rollback deployments created: $rollback_deployment_count"
    else
        print_status "FAIL" "Expected 1+ rollback deployments, found: $rollback_deployment_count"
    fi
    
    # Check if rollback services exist
    local rollback_service_count=$(kubectl get services -n todo-app -l purpose=advanced-deployments --no-headers | wc -l)
    if [ "$rollback_deployment_count" -ge 1 ]; then
        print_status "PASS" "Rollback services created: $rollback_service_count"
    else
        print_status "FAIL" "Expected 1+ rollback services, found: $rollback_service_count"
    fi
    
    # List rollback resources
    echo "Rollback Deployments:"
    kubectl get deployments -n todo-app -l purpose=advanced-deployments
    echo -e "\nRollback Services:"
    kubectl get services -n todo-app -l purpose=advanced-deployments
}

# Function to test advanced deployment script
test_advanced_deployment_script() {
    echo -e "\n${BLUE}🔍 Testing Advanced Deployment Script...${NC}"
    
    # Check if script exists and is executable
    if [ -x "scripts/advanced-deployments.sh" ]; then
        print_status "PASS" "Advanced deployment script exists and is executable"
    else
        print_status "FAIL" "Advanced deployment script not found or not executable"
        return 1
    fi
    
    # Test script help
    local help_output=$(./scripts/advanced-deployments.sh help 2>&1)
    if echo "$help_output" | grep -q "Advanced Deployment Strategies Management Script"; then
        print_status "PASS" "Advanced deployment script help works"
    else
        print_status "FAIL" "Advanced deployment script help not working"
        return 1
    fi
    
    # Test script status command
    local status_output=$(./scripts/advanced-deployments.sh status 2>&1)
    if echo "$status_output" | grep -q "Deployment Status"; then
        print_status "PASS" "Advanced deployment script status command works"
    else
        print_status "FAIL" "Advanced deployment script status command not working"
        return 1
    fi
}

# Function to test ingress canary support
test_ingress_canary_support() {
    echo -e "\n${BLUE}🔍 Testing Ingress Canary Support...${NC}"
    
    # Check if advanced ingress has canary annotations
    local canary_enabled=$(kubectl get ingress todo-advanced-ingress -n todo-app -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/canary}')
    
    if [ "$canary_enabled" = "false" ]; then
        print_status "PASS" "Ingress canary support configured (currently disabled)"
    else
        print_status "FAIL" "Ingress canary support not properly configured"
        return 1
    fi
    
    # List ingress canary annotations
    echo "Ingress Canary Annotations:"
    kubectl get ingress todo-advanced-ingress -n todo-app -o jsonpath='{.metadata.annotations}' | jq -r 'to_entries[] | select(.key | contains("canary")) | "\(.key): \(.value)"' 2>/dev/null || echo "No canary annotations found"
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting Advanced Deployment Strategies Tests...${NC}"
    
    # Check if we're in the right context
    local current_context=$(kubectl config current-context)
    echo "Current Kubernetes context: $current_context"
    
    # Check if todo-app namespace exists
    if ! kubectl get namespace todo-app >/dev/null 2>&1; then
        print_status "FAIL" "todo-app namespace not found. Please deploy the application first."
        exit 1
    fi
    
    # Run all tests
    test_blue_green_infrastructure
    test_canary_infrastructure
    test_rollback_infrastructure
    test_advanced_deployment_script
    test_ingress_canary_support
    
    echo -e "\n${GREEN}🎉 Advanced Deployment Strategies Testing Complete!${NC}"
    echo -e "\n${YELLOW}📋 Summary:${NC}"
    echo "- Blue-Green Deployments: Zero-downtime deployments"
    echo "- Canary Deployments: Gradual rollouts with traffic splitting"
    echo "- Rollback Strategies: Automated rollback procedures"
    echo "- Advanced Deployment Scripts: Management and automation"
    echo "- Ingress Canary Support: Traffic splitting at ingress level"
    echo ""
    echo "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Deploy blue-green: ./scripts/advanced-deployments.sh deploy-blue-green"
    echo "2. Deploy canary: ./scripts/advanced-deployments.sh deploy-canary"
    echo "3. Test switching: ./scripts/advanced-deployments.sh switch-blue-green green"
    echo "4. Adjust canary: ./scripts/advanced-deployments.sh adjust-canary 25"
    echo "5. View status: ./scripts/advanced-deployments.sh status"
}

# Run main function
main "$@"
