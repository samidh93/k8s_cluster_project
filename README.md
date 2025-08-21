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

# Deploy to local cluster
kubectl apply -f k8s/base/

# Check status
kubectl get all
```

### Production Deployment
```bash
# Deploy to production
kubectl apply -f k8s/overlays/production/
```

## Development

### Adding New Resources
1. Create manifest in `k8s/base/`
2. Update Kustomization files
3. Test locally with `kubectl apply -f k8s/base/`

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
