# Advanced Deployment Strategies Guide

## 🚀 Overview

This document describes the advanced deployment strategies implemented for the Todo application. These strategies provide zero-downtime deployments, gradual rollouts, automated rollbacks, and intelligent traffic management for production-grade Kubernetes applications.

## 🏗️ Architecture

### Deployment Strategies

1. **Blue-Green Deployments** - Zero-downtime deployments with instant switching
2. **Canary Deployments** - Gradual rollouts with traffic splitting and monitoring
3. **Rollback Strategies** - Automated rollback procedures with health checks
4. **Advanced Traffic Management** - Intelligent routing and load balancing
5. **Deployment Automation** - Scripts and tools for managing deployments

### Strategy Comparison

| Strategy | Use Case | Downtime | Risk | Rollback Speed |
|----------|----------|----------|------|----------------|
| **Blue-Green** | Major releases | Zero | Low | Instant |
| **Canary** | Feature testing | Zero | Very Low | Gradual |
| **Rolling Update** | Bug fixes | Minimal | Medium | Fast |
| **Rollback** | Emergency recovery | Minimal | Very Low | Instant |

## 🔧 Implementation

### 1. Blue-Green Deployments

Blue-green deployments maintain two identical production environments (blue and green) and switch traffic between them.

#### Infrastructure

```yaml
# Blue Deployment (Active)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-backend-blue
  labels:
    version: blue
    purpose: blue-green-deployment
spec:
  replicas: 2  # Active replicas
  selector:
    matchLabels:
      version: blue
```

```yaml
# Green Deployment (Standby)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-backend-green
  labels:
    version: green
    purpose: blue-green-deployment
spec:
  replicas: 0  # No replicas initially
  selector:
    matchLabels:
      version: green
```

#### Service Switching

```yaml
# Blue-Green Service
apiVersion: v1
kind: Service
metadata:
  name: todo-blue-green-service
  annotations:
    blue-green.kubernetes.io/active-deployment: "blue"
spec:
  selector:
    version: blue  # Points to active deployment
```

#### Deployment Process

1. **Deploy to Green**: Deploy new version to green environment
2. **Test Green**: Validate green deployment in isolation
3. **Switch Traffic**: Update service selector to point to green
4. **Scale Green**: Scale green to production replicas
5. **Scale Blue**: Scale blue to 0 replicas
6. **Monitor**: Verify green deployment health
7. **Rollback**: If issues, switch back to blue instantly

#### Commands

```bash
# Deploy blue-green infrastructure
./scripts/advanced-deployments.sh deploy-blue-green

# Switch to green deployment
./scripts/advanced-deployments.sh switch-blue-green green

# Switch back to blue deployment
./scripts/advanced-deployments.sh switch-blue-green blue

# Check status
./scripts/advanced-deployments.sh status
```

### 2. Canary Deployments

Canary deployments gradually roll out new versions to a subset of users while monitoring performance and health.

#### Infrastructure

```yaml
# Canary Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-backend-canary
  labels:
    version: canary
    purpose: canary-deployment
  annotations:
    canary.kubernetes.io/weight: "10"      # 10% traffic
    canary.kubernetes.io/phase: "testing"  # Current phase
spec:
  replicas: 1  # Minimal replicas initially
```

#### Traffic Splitting

```yaml
# Canary Service
apiVersion: v1
kind: Service
metadata:
  name: todo-canary-service
  annotations:
    canary.kubernetes.io/enabled: "true"
    canary.kubernetes.io/weight: "10"
spec:
  selector:
    version: canary
```

#### Deployment Process

1. **Deploy Canary**: Deploy new version with minimal replicas
2. **Set Initial Weight**: Start with 5-10% traffic
3. **Monitor Health**: Check metrics, logs, and user feedback
4. **Gradually Increase**: Incrementally increase traffic weight
5. **Full Promotion**: Scale to 100% when confident
6. **Cleanup**: Remove canary deployment

#### Commands

```bash
# Deploy canary version
./scripts/advanced-deployments.sh deploy-canary

# Adjust traffic weight
./scripts/advanced-deployments.sh adjust-canary 25  # 25% traffic

# Promote canary to production
./scripts/advanced-deployments.sh promote-canary

# Check status
./scripts/advanced-deployments.sh status
```

### 3. Rollback Strategies

Automated rollback procedures that detect deployment failures and revert to previous working versions.

#### Infrastructure

```yaml
# Deployment with Rollback
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-backend-with-rollback
  annotations:
    rollback.kubernetes.io/strategy: "automatic"
    rollback.kubernetes.io/failure-threshold: "3"
    rollback.kubernetes.io/rollback-delay: "60s"
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

#### Health Checks

```yaml
spec:
  template:
    spec:
      containers:
      - name: todo-backend
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          failureThreshold: 3
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          failureThreshold: 3
          timeoutSeconds: 5
```

#### Rollback Process

1. **Health Monitoring**: Continuous health check monitoring
2. **Failure Detection**: Detect when health checks fail
3. **Automatic Rollback**: Trigger rollback after failure threshold
4. **Previous Version**: Revert to last known good version
5. **Verification**: Confirm rollback success
6. **Notification**: Alert team of rollback event

#### Commands

```bash
# Manual rollback
./scripts/advanced-deployments.sh rollback todo-backend-with-rollback

# Check deployment history
kubectl rollout history deployment/todo-backend-with-rollback -n todo-app

# Rollback to specific revision
kubectl rollout undo deployment/todo-backend-with-rollback -n todo-app --to-revision=2
```

### 4. Advanced Traffic Management

Intelligent routing and load balancing at the ingress level.

#### Ingress Configuration

```yaml
# Advanced Ingress with Canary Support
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-advanced-ingress
  annotations:
    # Canary deployment support
    nginx.ingress.kubernetes.io/canary: "false"
    nginx.ingress.kubernetes.io/canary-weight: "0"
    
    # Load balancing
    nginx.ingress.kubernetes.io/load-balance: "round_robin"
    
    # Session affinity
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "todo-session"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

#### Traffic Splitting

```yaml
# Canary Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"  # 20% traffic
spec:
  rules:
  - host: todo.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: todo-canary-service
            port:
              number: 8080
```

## 🚀 Usage

### Deployment Workflows

#### Blue-Green Deployment Workflow

```bash
# 1. Deploy infrastructure
./scripts/advanced-deployments.sh deploy-blue-green

# 2. Update green deployment with new image
kubectl set image deployment/todo-backend-green todo-backend=ghcr.io/samidh93/todo-backend:v2.0.0 -n todo-app

# 3. Scale green to production replicas
kubectl scale deployment todo-backend-green -n todo-app --replicas=2

# 4. Wait for green to be ready
kubectl wait --for=condition=available deployment/todo-backend-green -n todo-app --timeout=300s

# 5. Switch traffic to green
./scripts/advanced-deployments.sh switch-blue-green green

# 6. Verify green deployment
kubectl get pods -n todo-app -l version=green

# 7. Scale down blue (optional)
kubectl scale deployment todo-backend-blue -n todo-app --replicas=0
```

#### Canary Deployment Workflow

```bash
# 1. Deploy canary version
./scripts/advanced-deployments.sh deploy-canary

# 2. Start with minimal traffic (5%)
./scripts/advanced-deployments.sh adjust-canary 5

# 3. Monitor canary health
kubectl logs -n todo-app -l version=canary --tail=100

# 4. Gradually increase traffic
./scripts/advanced-deployments.sh adjust-canary 25
./scripts/advanced-deployments.sh adjust-canary 50

# 5. Monitor metrics and user feedback
kubectl top pods -n todo-app -l version=canary

# 6. Promote to production
./scripts/advanced-deployments.sh promote-canary

# 7. Clean up canary
kubectl delete deployment todo-backend-canary -n todo-app
```

#### Rollback Workflow

```bash
# 1. Check deployment status
kubectl rollout status deployment/todo-backend-with-rollback -n todo-app

# 2. If deployment fails, check health
kubectl describe deployment todo-backend-with-rollback -n todo-app

# 3. Manual rollback
./scripts/advanced-deployments.sh rollback todo-backend-with-rollback

# 4. Verify rollback success
kubectl get pods -n todo-app -l app=todo-backend

# 5. Check deployment history
kubectl rollout history deployment/todo-backend-with-rollback -n todo-app
```

### Monitoring and Health Checks

#### Health Check Endpoints

```bash
# Backend health
curl http://localhost:8080/actuator/health

# Frontend health
curl http://localhost:8080/

# Service health
kubectl get endpoints -n todo-app
```

#### Metrics and Monitoring

```bash
# Pod metrics
kubectl top pods -n todo-app

# Deployment status
kubectl get deployments -n todo-app

# Service endpoints
kubectl get endpoints -n todo-app

# Ingress status
kubectl get ingress -n todo-app
```

## 🧪 Testing

### Test Advanced Deployment Strategies

```bash
# Run comprehensive tests
./scripts/test-advanced-deployments.sh

# Test specific components
./scripts/test-advanced-deployments.sh test_blue_green_infrastructure
./scripts/test-advanced-deployments.sh test_canary_infrastructure
./scripts/test_advanced_deployments.sh test_rollback_infrastructure
```

### Test Deployment Scripts

```bash
# Test script functionality
./scripts/advanced-deployments.sh help
./scripts/advanced-deployments.sh status

# Test deployment commands
./scripts/advanced-deployments.sh deploy-blue-green
./scripts/advanced-deployments.sh deploy-canary
```

## 🔒 Security

### Deployment Security

- **Service Account Isolation**: Each deployment strategy uses dedicated service accounts
- **RBAC Control**: Minimal required permissions for deployment operations
- **Network Policies**: Restricted pod-to-pod communication
- **Resource Limits**: CPU and memory limits for all deployments

### Traffic Security

- **Rate Limiting**: Prevent abuse and DDoS attacks
- **Session Affinity**: Secure user session management
- **Health Checks**: Continuous monitoring of deployment health
- **Rollback Protection**: Automatic recovery from failed deployments

## 🚨 Troubleshooting

### Common Issues

#### Blue-Green Deployment Issues

```bash
# Service selector mismatch
kubectl get service todo-blue-green-service -n todo-app -o yaml
kubectl get pods -n todo-app -l version=blue

# Deployment not ready
kubectl describe deployment todo-backend-blue -n todo-app
kubectl logs -n todo-app -l version=blue --tail=100
```

#### Canary Deployment Issues

```bash
# Traffic weight not applied
kubectl get deployment todo-backend-canary -n todo-app -o jsonpath='{.metadata.annotations.canary\.kubernetes\.io/weight}'

# Canary not receiving traffic
kubectl get endpoints -n todo-app
kubectl get service todo-canary-service -n todo-app
```

#### Rollback Issues

```bash
# Rollback failed
kubectl rollout status deployment/todo-backend-with-rollback -n todo-app
kubectl describe deployment todo-backend-with-rollback -n todo-app

# No deployment history
kubectl rollout history deployment/todo-backend-with-rollback -n todo-app
```

### Debugging Commands

```bash
# Check deployment events
kubectl get events -n todo-app --sort-by=.metadata.creationTimestamp

# Check pod logs
kubectl logs -n todo-app -l app=todo-backend --tail=100

# Check service endpoints
kubectl get endpoints -n todo-app

# Check ingress status
kubectl describe ingress todo-advanced-ingress -n todo-app
```

## 📈 Best Practices

### Deployment Strategy Selection

1. **Blue-Green**: Use for major releases and critical updates
2. **Canary**: Use for feature testing and gradual rollouts
3. **Rolling Update**: Use for bug fixes and minor updates
4. **Rollback**: Always have rollback capability for emergencies

### Health Monitoring

1. **Liveness Probes**: Detect and restart failed containers
2. **Readiness Probes**: Ensure traffic only goes to ready pods
3. **Metrics Collection**: Monitor performance and resource usage
4. **Log Analysis**: Track application behavior and errors

### Traffic Management

1. **Gradual Rollouts**: Start with minimal traffic and increase gradually
2. **Health Checks**: Verify deployment health before traffic increase
3. **Rollback Triggers**: Set appropriate failure thresholds
4. **Monitoring**: Continuous monitoring during deployment

### Security Considerations

1. **Service Account Isolation**: Use dedicated service accounts for each strategy
2. **Network Policies**: Restrict pod communication to minimum required
3. **Resource Limits**: Prevent resource exhaustion attacks
4. **Audit Logging**: Log all deployment operations

## 🔮 Future Enhancements

### Planned Features

1. **Automated Canary Analysis**: ML-based traffic analysis and promotion
2. **Cross-Region Deployments**: Geographic distribution and failover
3. **Advanced Traffic Splitting**: Header-based and cookie-based routing
4. **Deployment Analytics**: Performance metrics and success rates
5. **Integration with CI/CD**: Automated deployment triggers

### Integration Opportunities

1. **Monitoring Stack**: Prometheus metrics and Grafana dashboards
2. **Alerting**: Automated notifications for deployment events
3. **GitOps**: Git-based deployment management
4. **Service Mesh**: Istio integration for advanced traffic management

## 📚 References

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Blue-Green Deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Canary Deployment](https://martinfowler.com/bliki/CanaryRelease.html)
- [Kubernetes Rollbacks](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [Nginx Ingress Canary](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary)

## 🆘 Support

For advanced deployment strategy support:

1. **Check logs**: `kubectl logs -n todo-app -l purpose=advanced-deployments`
2. **Run tests**: `./scripts/test-advanced-deployments.sh`
3. **Check status**: `./scripts/advanced-deployments.sh status`
4. **Review documentation**: This guide and inline help
5. **Contact team**: DevOps/SRE team for complex issues

---

**Last Updated**: $(date)
**Version**: 1.0
**Maintainer**: DevOps Team
