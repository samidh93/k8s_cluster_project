#!/bin/bash

# Test Security & RBAC Implementation
echo "🔐 Testing Security & RBAC Implementation..."

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

# Function to test service accounts
test_service_accounts() {
    echo -e "\n${BLUE}🔍 Testing Service Accounts...${NC}"
    
    # Check if service accounts exist
    local sa_count=$(kubectl get serviceaccounts -n todo-app --no-headers | wc -l)
    if [ "$sa_count" -ge 4 ]; then
        print_status "PASS" "Service accounts created: $sa_count"
    else
        print_status "FAIL" "Expected 4+ service accounts, found: $sa_count"
    fi
    
    # List service accounts
    echo "Service Accounts in todo-app namespace:"
    kubectl get serviceaccounts -n todo-app
}

# Function to test RBAC
test_rbac() {
    echo -e "\n${BLUE}🔍 Testing RBAC...${NC}"
    
    # Check if roles exist
    local role_count=$(kubectl get roles -n todo-app --no-headers | wc -l)
    if [ "$role_count" -ge 4 ]; then
        print_status "PASS" "Roles created: $role_count"
    else
        print_status "FAIL" "Expected 4+ roles, found: $role_count"
    fi
    
    # Check if role bindings exist
    local rb_count=$(kubectl get rolebindings -n todo-app --no-headers | wc -l)
    if [ "$rb_count" -ge 4 ]; then
        print_status "PASS" "Role bindings created: $rb_count"
    else
        print_status "FAIL" "Expected 4+ role bindings, found: $rb_count"
    fi
    
    # List roles and role bindings
    echo "Roles in todo-app namespace:"
    kubectl get roles -n todo-app
    echo -e "\nRole Bindings in todo-app namespace:"
    kubectl get rolebindings -n todo-app
}

# Function to test security contexts
test_security_contexts() {
    echo -e "\n${BLUE}🔍 Testing Security Contexts...${NC}"
    
    # Check if pods are running as non-root
    local non_root_pods=$(kubectl get pods -n todo-app -o jsonpath='{.items[*].spec.securityContext.runAsNonRoot}' | grep -c "true" || echo "0")
    local total_pods=$(kubectl get pods -n todo-app --no-headers | wc -l)
    
    if [ "$non_root_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        print_status "PASS" "All $total_pods pods running as non-root"
    else
        print_status "FAIL" "Only $non_root_pods/$total_pods pods running as non-root"
    fi
    
    # Check security context details
    echo "Security Context Details:"
    kubectl get pods -n todo-app -o jsonpath='{range .items[*]}{.metadata.name}: runAsNonRoot={.spec.securityContext.runAsNonRoot}, runAsUser={.spec.securityContext.runAsUser}{"\n"}{end}'
}

# Function to test network policies
test_network_policies() {
    echo -e "\n${BLUE}🔍 Testing Network Policies...${NC}"
    
    # Check if network policies exist
    local np_count=$(kubectl get networkpolicies -n todo-app --no-headers | wc -l)
    if [ "$np_count" -ge 2 ]; then
        print_status "PASS" "Network policies created: $np_count"
    else
        print_status "FAIL" "Expected 2+ network policies, found: $np_count"
    fi
    
    # List network policies
    echo "Network Policies in todo-app namespace:"
    kubectl get networkpolicies -n todo-app
}

# Function to test secrets
test_secrets() {
    echo -e "\n${BLUE}🔍 Testing Secrets...${NC}"
    
    # Check if enhanced secrets exist
    local secret_count=$(kubectl get secrets -n todo-app --no-headers | wc -l)
    if [ "$secret_count" -ge 1 ]; then
        print_status "PASS" "Secrets created: $secret_count"
    else
        print_status "FAIL" "Expected 1+ secrets, found: $secret_count"
    fi
    
    # List secrets (without showing data)
    echo "Secrets in todo-app namespace:"
    kubectl get secrets -n todo-app
}

# Function to test pod security
test_pod_security() {
    echo -e "\n${BLUE}🔍 Testing Pod Security...${NC}"
    
    # Check if pods have security contexts
    local pods_with_sc=$(kubectl get pods -n todo-app -o jsonpath='{.items[*].spec.securityContext}' | grep -c "runAsNonRoot" || echo "0")
    local total_pods=$(kubectl get pods -n todo-app --no-headers | wc -l)
    
    if [ "$pods_with_sc" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        print_status "PASS" "All $total_pods pods have security contexts"
    else
        print_status "FAIL" "Only $pods_with_sc/$total_pods pods have security contexts"
    fi
}

# Function to test service account usage
test_service_account_usage() {
    echo -e "\n${BLUE}🔍 Testing Service Account Usage...${NC}"
    
    # Check if pods are using service accounts
    local pods_with_sa=$(kubectl get pods -n todo-app -o jsonpath='{.items[*].spec.serviceAccountName}' | grep -c -v "^$" || echo "0")
    local total_pods=$(kubectl get pods -n todo-app --no-headers | wc -l)
    
    if [ "$pods_with_sa" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        print_status "PASS" "All $total_pods pods using service accounts"
    else
        print_status "FAIL" "Only $pods_with_sa/$total_pods pods using service accounts"
    fi
    
    # Show service account usage
    echo "Service Account Usage:"
    kubectl get pods -n todo-app -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.serviceAccountName}{"\n"}{end}'
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting Security & RBAC Tests...${NC}"
    
    # Check if we're in the right context
    local current_context=$(kubectl config current-context)
    echo "Current Kubernetes context: $current_context"
    
    # Check if todo-app namespace exists
    if ! kubectl get namespace todo-app >/dev/null 2>&1; then
        print_status "FAIL" "todo-app namespace not found. Please deploy the application first."
        exit 1
    fi
    
    # Run all tests
    test_service_accounts
    test_rbac
    test_security_contexts
    test_network_policies
    test_secrets
    test_pod_security
    test_service_account_usage
    
    echo -e "\n${GREEN}🎉 Security & RBAC Testing Complete!${NC}"
    echo -e "\n${YELLOW}📋 Summary:${NC}"
    echo "- Service Accounts: Identity management for each component"
    echo "- RBAC: Fine-grained access control"
    echo "- Security Contexts: Non-root execution, capability dropping"
    echo "- Network Policies: Pod-to-pod communication control"
    echo "- Enhanced Secrets: Secure credential management"
    echo "- Pod Security: Baseline security standards"
}

# Run main function
main "$@"
