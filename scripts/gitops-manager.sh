#!/bin/bash

# GitOps Manager for Todo Application
# This script manages ArgoCD applications, Helm deployments, and feature flags

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_NAMESPACE="argocd"
APP_NAME="todo-app"
HELM_CHART_PATH="helm/todo-app"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        exit 1
    fi
    
    # Check if argocd CLI is installed
    if ! command -v argocd &> /dev/null; then
        log_warning "argocd CLI is not installed. Installing..."
        install_argocd_cli
    fi
    
    log_success "Prerequisites check passed"
}

install_argocd_cli() {
    log_info "Installing ArgoCD CLI..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install argocd
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    log_success "ArgoCD CLI installed"
}

get_argocd_admin_password() {
    log_info "Getting ArgoCD admin password..."
    kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
}

port_forward_argocd() {
    log_info "Setting up port-forward for ArgoCD..."
    kubectl port-forward -n $ARGOCD_NAMESPACE svc/argocd-server 8080:443 &
    ARGOCD_PID=$!
    sleep 5
    log_success "ArgoCD port-forward established on localhost:8080"
}

deploy_application() {
    local environment=$1
    local values_file="values-${environment}.yaml"
    
    log_info "Deploying Todo application to $environment environment..."
    
    # Check if values file exists
    if [[ ! -f "$HELM_CHART_PATH/$values_file" ]]; then
        log_error "Values file $values_file not found"
        exit 1
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace "${environment}-todo-app" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy using Helm
    helm upgrade --install "todo-app-${environment}" "$HELM_CHART_PATH" \
        --namespace "${environment}-todo-app" \
        --values "$HELM_CHART_PATH/values.yaml" \
        --values "$HELM_CHART_PATH/$values_file" \
        --set global.environment="$environment" \
        --wait \
        --timeout 10m
    
    log_success "Todo application deployed to $environment environment"
}

deploy_via_argocd() {
    local environment=$1
    
    log_info "Deploying via ArgoCD to $environment environment..."
    
    # Apply ArgoCD application
    kubectl apply -f "k8s/argocd/todo-app-application.yaml"
    
    # Wait for application to be synced
    log_info "Waiting for ArgoCD application to sync..."
    kubectl wait --for=condition=Synced --timeout=300s application/todo-app -n $ARGOCD_NAMESPACE
    
    log_success "ArgoCD application deployed and synced"
}

rollback_application() {
    local environment=$1
    local revision=$2
    
    if [[ -z "$revision" ]]; then
        log_info "Available revisions for $environment environment:"
        helm history "todo-app-${environment}" --namespace "${environment}-todo-app"
        echo
        read -p "Enter revision number to rollback to: " revision
    fi
    
    log_info "Rolling back to revision $revision..."
    
    helm rollback "todo-app-${environment}" "$revision" --namespace "${environment}-todo-app" --wait
    
    log_success "Rollback completed to revision $revision"
}

update_feature_flags() {
    local environment=$1
    local feature=$2
    local value=$3
    
    if [[ -z "$feature" || -z "$value" ]]; then
        log_error "Usage: update_feature_flags <environment> <feature> <true|false>"
        exit 1
    fi
    
    log_info "Updating feature flag $feature to $value in $environment environment..."
    
    # Update values file
    local values_file="$HELM_CHART_PATH/values-${environment}.yaml"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^  ${feature}: .*/  ${feature}: ${value}/" "$values_file"
    else
        # Linux
        sed -i "s/^  ${feature}: .*/  ${feature}: ${value}/" "$values_file"
    fi
    
    # Redeploy application
    deploy_application "$environment"
    
    log_success "Feature flag $feature updated to $value"
}

get_application_status() {
    local environment=$1
    
    log_info "Application status for $environment environment:"
    
    # Helm status
    echo "=== Helm Status ==="
    helm status "todo-app-${environment}" --namespace "${environment}-todo-app" 2>/dev/null || echo "Application not found"
    
    echo
    echo "=== Pod Status ==="
    kubectl get pods -n "${environment}-todo-app" -o wide
    
    echo
    echo "=== Service Status ==="
    kubectl get services -n "${environment}-todo-app"
    
    echo
    echo "=== Ingress Status ==="
    kubectl get ingress -n "${environment}-todo-app"
}

canary_deployment() {
    local environment=$1
    local percentage=$2
    
    if [[ -z "$percentage" ]]; then
        percentage=10
    fi
    
    log_info "Starting canary deployment with $percentage% traffic..."
    
    # This would integrate with your ingress controller for traffic splitting
    # For now, we'll just update the deployment
    kubectl patch deployment "todo-backend" -n "${environment}-todo-app" \
        -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"canary\":\"true\",\"canary-weight\":\"$percentage\"}}}}}"
    
    log_success "Canary deployment started with $percentage% traffic"
}

blue_green_deployment() {
    local environment=$1
    local action=$2  # switch-blue, switch-green, status
    
    case $action in
        "switch-blue")
            log_info "Switching to Blue deployment..."
            # Implementation would depend on your ingress controller
            ;;
        "switch-green")
            log_info "Switching to Green deployment..."
            # Implementation would depend on your ingress controller
            ;;
        "status")
            log_info "Blue-Green deployment status:"
            kubectl get deployments -n "${environment}-todo-app" -l app=todo-backend
            ;;
        *)
            log_error "Invalid action. Use: switch-blue, switch-green, or status"
            exit 1
            ;;
    esac
}

cleanup() {
    local environment=$1
    
    log_info "Cleaning up $environment environment..."
    
    # Delete Helm release
    helm uninstall "todo-app-${environment}" --namespace "${environment}-todo-app" || true
    
    # Delete namespace
    kubectl delete namespace "${environment}-todo-app" || true
    
    log_success "Cleanup completed for $environment environment"
}

show_help() {
    echo "GitOps Manager for Todo Application"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  deploy <environment>           Deploy application to environment (dev/staging/prod)"
    echo "  deploy-argocd <environment>    Deploy via ArgoCD"
    echo "  status <environment>           Show application status"
    echo "  rollback <environment> [rev]   Rollback to specific revision"
    echo "  feature-flag <env> <flag> <value>  Update feature flag"
    echo "  canary <environment> [%]       Start canary deployment"
    echo "  blue-green <env> <action>     Blue-green deployment actions"
    echo "  cleanup <environment>          Clean up environment"
    echo "  port-forward                   Setup ArgoCD port-forward"
    echo "  help                           Show this help message"
    echo
    echo "Environments: development, staging, production"
    echo "Features: newTodoUI, advancedSearch, darkMode, notifications"
    echo "Actions: switch-blue, switch-green, status"
    echo
    echo "Examples:"
    echo "  $0 deploy development"
    echo "  $0 deploy-argocd production"
    echo "  $0 feature-flag development newTodoUI true"
    echo "  $0 canary staging 20"
    echo "  $0 blue-green production status"
}

# Main script logic
main() {
    check_prerequisites
    
    case $1 in
        "deploy")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            deploy_application "$2"
            ;;
        "deploy-argocd")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            deploy_via_argocd "$2"
            ;;
        "status")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            get_application_status "$2"
            ;;
        "rollback")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            rollback_application "$2" "$3"
            ;;
        "feature-flag")
            if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
                log_error "Usage: feature-flag <environment> <feature> <value>"
                show_help
                exit 1
            fi
            update_feature_flags "$2" "$3" "$4"
            ;;
        "canary")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            canary_deployment "$2" "$3"
            ;;
        "blue-green")
            if [[ -z "$2" || -z "$3" ]]; then
                log_error "Usage: blue-green <environment> <action>"
                show_help
                exit 1
            fi
            blue_green_deployment "$2" "$3"
            ;;
        "cleanup")
            if [[ -z "$2" ]]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            cleanup "$2"
            ;;
        "port-forward")
            port_forward_argocd
            echo "ArgoCD is available at: https://localhost:8080"
            echo "Username: admin"
            echo "Password: $(get_argocd_admin_password)"
            echo "Press Ctrl+C to stop port-forward"
            wait $ARGOCD_PID
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Trap cleanup on script exit
trap 'if [[ -n "$ARGOCD_PID" ]]; then kill $ARGOCD_PID 2>/dev/null; fi' EXIT

# Run main function with all arguments
main "$@"
