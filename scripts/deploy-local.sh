#!/bin/bash

echo "🚀 Deploying Todo App to Local Minikube Cluster..."

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "⚠️  Minikube is not running. Starting minikube..."
    minikube start
fi

# Enable ingress addon if not enabled
if ! minikube addons list | grep -q "ingress.*enabled"; then
    echo "🔧 Enabling Ingress addon..."
    minikube addons enable ingress
fi

# Wait for ingress controller to be ready
echo "⏳ Waiting for Ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Apply the Todo app manifests
echo "📦 Applying Todo app manifests..."
kubectl apply -k k8s/overlays/development/

# Wait for all pods to be ready
echo "⏳ Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -n todo-app --timeout=300s

# Show deployment status
echo "📊 Deployment Status:"
kubectl get pods -n todo-app
kubectl get services -n todo-app
kubectl get ingress -n todo-app

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo ""
echo "🌐 Todo App is accessible at:"
echo "   Frontend: http://$MINIKUBE_IP"
echo "   Backend API: http://$MINIKUBE_IP/api"
echo "   Health Check: http://$MINIKUBE_IP/actuator/health"
echo ""
echo "💡 To access the app, you may need to add to /etc/hosts:"
echo "   $MINIKUBE_IP todo.local"
echo ""
echo "🔍 To view logs:"
echo "   kubectl logs -f deployment/todo-backend -n todo-app"
echo "   kubectl logs -f deployment/todo-frontend -n todo-app"
echo "   kubectl logs -f deployment/todo-nginx -n todo-app"
echo ""
echo "✅ Local deployment completed!"
