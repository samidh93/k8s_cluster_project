# Kubernetes Project

A modern Kubernetes project with best practices for deployment and management.

## Project Structure

```
├── k8s/                    # Kubernetes manifests
│   ├── base/              # Base configurations (Kustomize)
│   ├── overlays/          # Environment-specific overlays
│   ├── namespaces/        # Namespace definitions
│   └── crds/              # Custom Resource Definitions
├── helm/                   # Helm charts (if using Helm)
├── scripts/                # Deployment and utility scripts
├── docs/                   # Documentation
├── examples/               # Example configurations
├── tests/                  # Testing manifests
├── .github/                # GitHub Actions (CI/CD)
├── Makefile                # Build/deployment commands
└── README.md               # Project documentation

```

## Quick Start

### Prerequisites
- kubectl
- minikube or kind
- Docker

### Local Development
```bash
# Start local cluster
minikube start

# Deploy to local cluster (uses development overlay)
kubectl apply -k k8s/overlays/development/

# Check status
kubectl get all
```

**Note**: We use `k8s/overlays/development/` instead of `k8s/base/` because:
- Base contains Kustomization files (not Kubernetes resources)
- Overlays handle namespace creation and environment-specific configuration
- This ensures proper resource ordering and environment labeling

### Production Deployment
```bash
# Deploy to production
kubectl apply -f k8s/overlays/production/
```

## Development

### Adding New Resources
1. Create manifest in `k8s/base/`
2. Update Kustomization files
3. Test locally with `kubectl apply -k k8s/overlays/development/`

### Environment Overlays
- `k8s/overlays/development/` - Development environment
- `k8s/overlays/staging/` - Staging environment  
- `k8s/overlays/production/` - Production environment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `kubectl apply`
5. Submit a pull request

## License

MIT
# Test CI/CD pipeline without deployment
