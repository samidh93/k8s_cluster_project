# Deployment Guide

This document describes how to deploy the application to different environments.

## Environments

### Development
- **Replicas**: 1
- **Resources**: Minimal (64Mi memory, 250m CPU)
- **Purpose**: Local development and testing

### Staging
- **Replicas**: 2
- **Resources**: Medium (96Mi memory, 375m CPU)
- **Purpose**: Integration testing and QA

### Production
- **Replicas**: 3
- **Resources**: High (128Mi memory, 500m CPU)
- **Purpose**: Live production environment

## Deployment Commands

### Using Make
```bash
# Deploy to development
make deploy-dev

# Deploy to staging
make deploy-staging

# Deploy to production
make deploy-prod

# Clean up
make clean
```

### Using Scripts
```bash
# Deploy to specific environment
./scripts/deploy.sh development
./scripts/deploy.sh staging
./scripts/deploy.sh production

# Clean up specific environment
./scripts/cleanup.sh development
```

### Using kubectl directly
```bash
# Deploy using Kustomize
kubectl apply -k k8s/overlays/development/
kubectl apply -k k8s/overlays/staging/
kubectl apply -k k8s/overlays/production/

# Check status
kubectl get all -n app
kubectl rollout status deployment/app -n app
```

## Monitoring

### Check Pod Status
```bash
kubectl get pods -n app
kubectl describe pod <pod-name> -n app
```

### Check Logs
```bash
kubectl logs -f deployment/app -n app
```

### Check Events
```bash
kubectl get events -n app --sort-by='.lastTimestamp'
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Check if the image exists and is accessible
2. **CrashLoopBackOff**: Check pod logs for application errors
3. **Pending**: Check resource availability and node capacity

### Debug Commands
```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n app

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n app
```
