#!/bin/bash

# Deploy script for Kubernetes
set -e

ENVIRONMENT=${1:-development}
NAMESPACE="app"

echo "Deploying to $ENVIRONMENT environment..."

# Validate manifests
echo "Validating manifests..."
kubectl kustomize k8s/overlays/$ENVIRONMENT/ | kubectl apply --dry-run=client -f -

# Apply manifests
echo "Applying manifests..."
kubectl apply -k k8s/overlays/$ENVIRONMENT/

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl -n $NAMESPACE rollout status deployment/app --timeout=300s

echo "Deployment to $ENVIRONMENT completed successfully!"

# Show status
echo "Current status:"
kubectl -n $NAMESPACE get all
