.PHONY: help deploy-dev deploy-staging deploy-prod clean status logs build-frontend build-backend build-all db-setup db-test docker-up docker-down docker-logs

# Default target
help:
	@echo "Available commands:"
	@echo ""
	@echo "Database & Infrastructure:"
	@echo "  db-setup       - Setup PostgreSQL and Redis databases"
	@echo "  db-test        - Test database connection"
	@echo "  docker-up      - Start all services with Docker Compose"
	@echo "  docker-down    - Stop all services"
	@echo "  docker-logs    - Show logs for all services"
	@echo "  docker-status  - Show service status"
	@echo ""
	@echo "Build & Development:"
	@echo "  build-frontend - Build React frontend"
	@echo "  build-backend  - Build Java backend"
	@echo "  build-all      - Build all components"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy-dev     - Deploy to development environment"
	@echo "  deploy-staging - Deploy to staging environment"
	@echo "  deploy-prod    - Deploy to production environment"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean          - Clean up all resources"
	@echo "  status         - Show cluster status"
	@echo "  logs           - Show logs for all pods"

# Build targets
build-frontend:
	@echo "Building React frontend..."
	cd src/frontend && npm install && npm run build

build-backend:
	@echo "Building Java backend..."
	cd src/backend && mvn clean package -DskipTests

build-all: build-frontend build-backend
	@echo "All components built successfully!"

# Database operations
db-setup:
	@echo "Setting up PostgreSQL database..."
	@if command -v docker-compose >/dev/null 2>&1; then \
		echo "Using Docker Compose for database setup..."; \
		docker-compose up -d postgres redis; \
		echo "Waiting for database to be ready..."; \
		sleep 10; \
		echo "Database setup complete!"; \
	else \
		echo "Docker Compose not found. Please install it or run database setup manually."; \
		echo "See src/database/README.md for manual setup instructions."; \
	fi

db-test:
	@echo "Testing database connection..."
	@if command -v psql >/dev/null 2>&1; then \
		psql -h localhost -p 5433 -U postgres -d tododb -c "SELECT version();" || \
		echo "Database connection failed. Please ensure PostgreSQL is running on port 5433."; \
	else \
		echo "PostgreSQL client not found. Please install it to test database connection."; \
	fi

# Docker Compose operations
docker-up:
	@echo "Starting all services with Docker Compose..."
	docker-compose up -d
	@echo "All services started! Check status with: make docker-status"

docker-down:
	@echo "Stopping all services..."
	docker-compose down
	@echo "All services stopped!"

docker-logs:
	@echo "Showing logs for all services..."
	docker-compose logs -f

docker-status:
	@echo "Service status:"
	docker-compose ps

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
