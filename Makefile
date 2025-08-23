.PHONY: help deploy-dev deploy-staging deploy-prod clean status logs build-frontend build-backend build-all

# Default target
help:
	@echo "Available commands:"
	@echo "  build-frontend  - Build React frontend"
	@echo "  build-backend   - Build Java backend"
	@echo "  build-all       - Build both frontend and backend"
	@echo "  deploy-dev      - Deploy to development environment"
	@echo "  deploy-staging  - Deploy to staging environment"
	@echo "  deploy-prod     - Deploy to production environment"
	@echo "  clean           - Clean up all resources"
	@echo "  status          - Show cluster status"
	@echo "  logs            - Show logs for all pods"

# Build targets
build-frontend:
	@echo "Building React frontend..."
	cd src/frontend && npm install && npm run build

build-backend:
	@echo "Building Java backend..."
	cd src/backend && mvn clean package -DskipTests

build-all: build-frontend build-backend
	@echo "All components built successfully!"

# Development deployment
deploy-dev: build-all
	kubectl apply -k k8s/overlays/development/

# Staging deployment
deploy-staging:
	kubectl apply -k k8s/overlays/staging/

# Production deployment
deploy-prod:
	kubectl apply -k k8s/overlays/production/

# Clean up all resources
clean:
	@echo "Cleaning up all environments..."
	kubectl delete namespace app --ignore-not-found=true || true
	@echo "Cleanup completed"

# Show cluster status
status:
	kubectl get all --all-namespaces

# Show logs for all pods
logs:
	kubectl logs --all-containers=true --all-namespaces=true --tail=100

# Validate manifests
validate:
	kubectl kustomize k8s/base/ | kubectl apply --dry-run=client -f -
