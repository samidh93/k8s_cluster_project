# Environment Configuration Comparison

## Overview
This document outlines the differences between our three Kubernetes environments: Development, Staging, and Production.

## Environment Summary

| Component | Development | Staging | Production |
|-----------|-------------|---------|------------|
| **Purpose** | Local testing & development | Pre-production testing | Live production |
| **Replicas** | 1 of each | 2 of each (except DB) | 3 of each (except DB) |
| **Resource Limits** | Minimal | Medium | High |
| **Namespace** | `todo-app` | `todo-app` | `todo-app` |

## Detailed Configuration

### Development Environment
- **Location**: `k8s/overlays/development/`
- **Use Case**: Local development and testing
- **Scaling**: Single replica for all services
- **Resources**: Minimal allocation for local development

**Deployments:**
- `todo-backend`: 1 replica, 250m CPU, 256Mi RAM
- `todo-frontend`: 1 replica, 250m CPU, 256Mi RAM  
- `todo-nginx`: 1 replica, 100m CPU, 128Mi RAM
- `todo-postgres`: 1 replica, 250m CPU, 256Mi RAM

### Staging Environment
- **Location**: `k8s/overlays/staging/`
- **Use Case**: Pre-production testing and validation
- **Scaling**: Multiple replicas for load testing
- **Resources**: Medium allocation for testing under load

**Deployments:**
- `todo-backend`: 2 replicas, 500m CPU, 512Mi RAM
- `todo-frontend`: 2 replicas, 250m CPU, 256Mi RAM
- `todo-nginx`: 2 replicas, 100m CPU, 128Mi RAM
- `todo-postgres`: 1 replica, 250m CPU, 256Mi RAM

### Production Environment
- **Location**: `k8s/overlays/production/`
- **Use Case**: Live production serving real users
- **Scaling**: High availability with multiple replicas
- **Resources**: High allocation for production workloads

**Deployments:**
- `todo-backend`: 3 replicas, 1000m CPU, 1Gi RAM
- `todo-frontend`: 3 replicas, 500m CPU, 512Mi RAM
- `todo-nginx`: 3 replicas, 200m CPU, 256Mi RAM
- `todo-postgres`: 1 replica, 500m CPU, 512Mi RAM

## Resource Allocation Strategy

### CPU Allocation
- **Development**: Minimal (250m-100m) for local development
- **Staging**: Medium (250m-500m) for load testing
- **Production**: High (500m-1000m) for production workloads

### Memory Allocation
- **Development**: Minimal (128Mi-256Mi) for local development
- **Staging**: Medium (128Mi-512Mi) for load testing
- **Production**: High (256Mi-1Gi) for production workloads

### Scaling Strategy
- **Database**: Single replica across all environments (data consistency)
- **Application Services**: Scaled based on environment needs
- **Load Balancer**: Scaled for high availability in staging/production

## Deployment Commands

### Development
```bash
kubectl apply -k k8s/overlays/development/
```

### Staging
```bash
kubectl apply -k k8s/overlays/staging/
```

### Production
```bash
kubectl apply -k k8s/overlays/production/
```

## Environment Switching

To switch between environments:

1. **Stop current environment**:
   ```bash
   kubectl delete -k k8s/overlays/development/
   ```

2. **Deploy new environment**:
   ```bash
   kubectl apply -k k8s/overlays/staging/
   ```

3. **Verify deployment**:
   ```bash
   kubectl get pods -n todo-app
   kubectl get services -n todo-app
   ```

## Next Steps

1. ✅ **Multi-Environment Setup** - COMPLETED
2. 🔄 **Horizontal Pod Autoscaling (HPA)** - NEXT
3. 📊 **Resource Optimization** - PLANNED
4. ⚖️ **Load Balancing & Traffic Management** - PLANNED
5. 🚨 **Production-Grade Monitoring** - PLANNED
6. 🔒 **Security Hardening** - PLANNED
7. 💾 **Backup & Disaster Recovery** - PLANNED
