#!/bin/bash

# HPA Testing and Monitoring Script
# Usage: ./scripts/test-hpa.sh [environment] [action]

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-status}

echo "🚀 HPA Testing and Monitoring for $ENVIRONMENT Environment"
echo "========================================================"

case $ACTION in
    "status")
        echo "📊 Current HPA Status:"
        kubectl get hpa -n todo-app
        
        echo ""
        echo "📈 HPA Details:"
        kubectl describe hpa todo-backend-hpa -n todo-app
        
        echo ""
        echo "🔍 Current Pod Status:"
        kubectl get pods -n todo-app -l app=todo-backend
        
        echo ""
        echo "📊 Resource Usage:"
        kubectl top pods -n todo-app -l app=todo-backend
        ;;
        
    "deploy")
        echo "🚀 Deploying to $ENVIRONMENT environment..."
        kubectl apply -k k8s/overlays/$ENVIRONMENT/
        
        echo ""
        echo "⏳ Waiting for deployment to be ready..."
        kubectl wait --for=condition=ready pod -l app=todo-backend -n todo-app --timeout=300s
        
        echo ""
        echo "✅ Deployment completed! Checking HPA status..."
        kubectl get hpa -n todo-app
        ;;
        
    "load-test")
        echo "🔥 Starting Load Test to Trigger HPA Scaling..."
        echo "This will generate traffic to increase CPU/Memory usage"
        
        # Get the service URL
        SERVICE_URL=$(kubectl get service todo-nginx -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -z "$SERVICE_URL" ]; then
            echo "⚠️  No external IP found. Using port-forward..."
            echo "🔌 Please run: kubectl port-forward -n todo-app service/todo-nginx 8080:80"
            SERVICE_URL="localhost:8080"
        fi
        
        echo "🎯 Target URL: $SERVICE_URL"
        echo "📊 Starting load test with 100 concurrent requests..."
        
        # Simple load test using curl
        for i in {1..100}; do
            curl -s "$SERVICE_URL/api/todos" > /dev/null &
            if [ $((i % 10)) -eq 0 ]; then
                echo "📈 Sent $i requests..."
            fi
        done
        
        wait
        echo "✅ Load test completed!"
        echo "📊 Check HPA status: ./scripts/test-hpa.sh $ENVIRONMENT status"
        ;;
        
    "monitor")
        echo "📊 Monitoring HPA and Pod Scaling in Real-time..."
        echo "Press Ctrl+C to stop monitoring"
        
        while true; do
            clear
            echo "🔄 HPA Monitoring - $(date)"
            echo "=================================="
            
            echo "📈 HPA Status:"
            kubectl get hpa -n todo-app
            
            echo ""
            echo "🔍 Pod Status:"
            kubectl get pods -n todo-app -l app=todo-backend -o wide
            
            echo ""
            echo "📊 Resource Usage:"
            kubectl top pods -n todo-app -l app=todo-backend 2>/dev/null || echo "Metrics server not available"
            
            echo ""
            echo "📝 Recent HPA Events:"
            kubectl get events -n todo-app --sort-by='.lastTimestamp' | grep -i hpa | tail -5
            
            sleep 5
        done
        ;;
        
    "cleanup")
        echo "🧹 Cleaning up HPA deployment..."
        kubectl delete -k k8s/overlays/$ENVIRONMENT/
        echo "✅ Cleanup completed!"
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo ""
        echo "Available actions:"
        echo "  status    - Show current HPA status"
        echo "  deploy    - Deploy to specified environment"
        echo "  load-test - Run load test to trigger scaling"
        echo "  monitor   - Real-time monitoring of HPA"
        echo "  cleanup   - Remove deployment"
        echo ""
        echo "Usage: $0 [environment] [action]"
        echo "Environments: development, staging, production"
        exit 1
        ;;
esac
