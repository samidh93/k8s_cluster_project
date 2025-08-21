#!/bin/bash

# Cleanup script for Kubernetes
set -e

ENVIRONMENT=${1:-development}
NAMESPACE="app"

echo "Cleaning up $ENVIRONMENT environment..."

# Delete resources
kubectl delete -k k8s/overlays/$ENVIRONMENT/ || true

# Delete namespace if it exists
kubectl delete namespace $NAMESPACE || true

echo "Cleanup of $ENVIRONMENT environment completed!"
