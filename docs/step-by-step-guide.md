# 🚀 KubeTodoApp - Step-by-Step Project Guide

This comprehensive guide will walk you through setting up, deploying, and managing the **KubeTodoApp** project from start to finish.

## 📋 Prerequisites Checklist

Before starting, ensure you have the following installed:

- [ ] **Docker** 20.10+ - Container runtime
- [ ] **kubectl** 1.25+ - Kubernetes command-line tool
- [ ] **minikube** 1.30+ - Local Kubernetes cluster
- [ ] **Helm** 3.10+ - Kubernetes package manager
- [ ] **Git** 2.30+ - Version control
- [ ] **Java 17** - Backend development
- [ ] **Node.js 18** - Frontend development
- [ ] **Maven** 3.8+ - Java build tool

## 🎯 Step 1: Project Setup

### 1.1 Clone the Repository
```bash
git clone https://github.com/samidh93/kubetodoapp.git
cd kubetodoapp
```

### 1.2 Verify Project Structure
```bash
ls -la
# Should show: src/, k8s/, helm/, docker/, docs/, scripts/
```

### 1.3 Check Dependencies
```bash
# Verify Docker
docker --version

# Verify Kubernetes
kubectl version --client

# Verify Minikube
minikube version

# Verify Helm
helm version
```

## 🏗️ Step 2: Local Development Setup

### 2.1 Start Local Kubernetes Cluster
```bash
# Start minikube with required addons
minikube start
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster is running
kubectl get nodes
```

### 2.2 Build and Test Locally (Optional)
```bash
# Start with Docker Compose for local testing
docker-compose up -d

# Test the application
curl http://localhost:3000/api/todos/statistics

# Stop local services
docker-compose down
```

## 🐳 Step 3: Container Image Building

### 3.1 Build Frontend Image
```bash
# Build React application
cd src/frontend
npm install
npm run build

# Build Docker image
cd ../..
docker build -f docker/frontend.Dockerfile -t todo-frontend:latest .
```

### 3.2 Build Backend Image
```bash
# Build Spring Boot application
cd src/backend
./mvnw clean package -DskipTests

# Build Docker image
cd ../..
docker build -f docker/backend.Dockerfile -t todo-backend:latest .
```

### 3.3 Build Nginx Image
```bash
# Build Nginx proxy image
docker build -f docker/nginx.Dockerfile -t todo-nginx:latest .
```

### 3.4 Load Images into Minikube
```bash
# Load all images into minikube
minikube image load todo-frontend:latest
minikube image load todo-backend:latest
minikube image load todo-nginx:latest
```

## 🚀 Step 4: Kubernetes Deployment

### 4.1 Deploy with Helm (Recommended)
```bash
# Create namespace
kubectl create namespace development-todo-app

# Deploy application
helm install todo-app ./helm/todo-app \
  --namespace development-todo-app \
  --set global.environment=development

# Verify deployment
kubectl get pods -n development-todo-app
```

### 4.2 Deploy with Kustomize (Alternative)
```bash
# Deploy base configuration
kubectl apply -k k8s/overlays/development/

# Verify deployment
kubectl get all -n development-todo-app
```

### 4.3 Access the Application
```bash
# Get application URL
minikube service todo-app-nginx --url -n development-todo-app

# Or use port forwarding
kubectl port-forward -n development-todo-app service/todo-app-nginx 3000:80
```

**Application URLs:**
- **Frontend**: http://localhost:3000
- **API**: http://localhost:3000/api
- **Health Check**: http://localhost:3000/actuator/health

## 📊 Step 5: Monitoring Setup

### 5.1 Deploy Monitoring Stack
```bash
# Deploy Prometheus and Grafana
kubectl apply -k k8s/monitoring/

# Verify monitoring pods
kubectl get pods -n monitoring
```

### 5.2 Access Monitoring Tools
```bash
# Access Prometheus
kubectl port-forward -n monitoring service/prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring service/grafana 3001:3000
```

**Monitoring URLs:**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001 (admin/admin)

## 🔄 Step 6: GitOps Setup (ArgoCD)

### 6.1 Install ArgoCD
```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 6.2 Access ArgoCD
```bash
# Port forward to ArgoCD
kubectl port-forward -n argocd service/argocd-server 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**ArgoCD URL**: https://localhost:8080
**Username**: admin
**Password**: (from command above)

### 6.3 Deploy Application via ArgoCD
```bash
# Deploy Todo application
kubectl apply -f k8s/argocd/todo-app-application.yaml

# Verify ArgoCD application
kubectl get applications -n argocd
```

## 🔧 Step 7: CI/CD Pipeline Setup

### 7.1 GitHub Actions Configuration
The CI/CD pipeline is already configured in `.github/workflows/ci-cd.yml`. It includes:

- **Parallel Build Jobs**: Backend, Frontend, Docker builds
- **Automated Testing**: Unit tests, integration tests
- **Security Scanning**: Vulnerability assessment
- **Image Publishing**: Automatic push to GitHub Container Registry
- **GitOps Integration**: Automatic ArgoCD sync

### 7.2 Pipeline Triggers
The pipeline automatically runs on:
- **Push to main/develop branches**
- **Pull requests to main/develop**
- **Manual workflow dispatch**

### 7.3 Monitor Pipeline Status
```bash
# Check GitHub Actions status
gh run list

# View specific run details
gh run view <run-id>
```

## 🧪 Step 8: Testing and Validation

### 8.1 Application Testing
```bash
# Test API endpoints
curl http://localhost:3000/api/todos/statistics
curl http://localhost:3000/api/todos
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Todo","description":"Test Description","priority":"HIGH"}'
```

### 8.2 Load Testing
```bash
# Run load tests (if available)
cd scripts
./test-load-balancing.sh
./test-hpa.sh
```

### 8.3 Security Testing
```bash
# Run security tests
cd scripts
./test-security.sh
```

## 🔍 Step 9: Troubleshooting

### 9.1 Common Issues

#### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n development-todo-app

# Check pod logs
kubectl logs -n development-todo-app <pod-name>

# Describe pod for events
kubectl describe pod -n development-todo-app <pod-name>
```

#### Service Not Accessible
```bash
# Check services
kubectl get services -n development-todo-app

# Check endpoints
kubectl get endpoints -n development-todo-app

# Test service connectivity
kubectl exec -n development-todo-app <pod-name> -- curl http://service-name:port
```

#### Image Pull Issues
```bash
# Check image pull secrets
kubectl get secrets -n development-todo-app

# Verify image exists
docker images | grep todo

# Load image into minikube
minikube image load <image-name>:<tag>
```

### 9.2 Debugging Commands
```bash
# Get all resources
kubectl get all -n development-todo-app

# Check events
kubectl get events -n development-todo-app --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n development-todo-app
kubectl top nodes
```

## 🧹 Step 10: Cleanup

### 10.1 Remove Application
```bash
# Remove with Helm
helm uninstall todo-app -n development-todo-app

# Or remove with kubectl
kubectl delete -k k8s/overlays/development/
```

### 10.2 Remove Monitoring
```bash
# Remove monitoring stack
kubectl delete -k k8s/monitoring/
```

### 10.3 Remove ArgoCD
```bash
# Remove ArgoCD
kubectl delete namespace argocd
```

### 10.4 Clean Up Minikube
```bash
# Stop minikube
minikube stop

# Delete cluster
minikube delete
```

## 📚 Next Steps

### Development
1. **Add new features** to the application
2. **Update documentation** as needed
3. **Add tests** for new functionality
4. **Create pull requests** for changes

### Production
1. **Configure production values** in Helm charts
2. **Set up production monitoring** and alerting
3. **Implement backup strategies** for data
4. **Configure security policies** and RBAC

### Advanced Features
1. **Implement blue-green deployments**
2. **Add canary releases**
3. **Set up disaster recovery**
4. **Configure auto-scaling policies**

## 🆘 Support

If you encounter issues:

1. **Check the logs** using the troubleshooting commands above
2. **Review the documentation** in the `docs/` directory
3. **Open an issue** on GitHub with detailed information
4. **Check the CI/CD pipeline** status for build issues

## 📖 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Happy Deploying! 🚀**
