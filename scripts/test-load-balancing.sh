#!/bin/bash

# Load Balancing and Traffic Management Testing Script
# Usage: ./scripts/test-load-balancing.sh [environment] [action]

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-status}

echo "⚖️  Load Balancing and Traffic Management Testing for $ENVIRONMENT Environment"
echo "========================================================================"

case $ACTION in
    "status")
        echo "📊 Current Load Balancing Status:"
        echo ""
        echo "🔍 Nginx Pods:"
        kubectl get pods -n todo-app -l app=todo-nginx -o wide
        
        echo ""
        echo "🌐 Services:"
        kubectl get services -n todo-app
        
        echo ""
        echo "🚪 Ingress:"
        kubectl get ingress -n todo-app
        
        echo ""
        echo "🔒 Network Policies:"
        kubectl get networkpolicies -n todo-app
        
        echo ""
        echo "📈 Pod Distribution:"
        kubectl get pods -n todo-app -o wide | grep -E "(todo-nginx|todo-backend)"
        ;;
        
    "deploy")
        echo "🚀 Deploying Load Balancing Configuration to $ENVIRONMENT environment..."
        kubectl apply -k k8s/overlays/$ENVIRONMENT/
        
        echo ""
        echo "⏳ Waiting for nginx pods to be ready..."
        kubectl wait --for=condition=ready pod -l app=todo-nginx -n todo-app --timeout=300s
        
        echo ""
        echo "✅ Deployment completed! Checking load balancing status..."
        kubectl get pods -n todo-app -l app=todo-nginx
        ;;
        
    "test-load-balancing")
        echo "🔄 Testing Load Balancing Distribution..."
        echo "This will send requests and show which nginx pod handles each request"
        
        # Get nginx pod names
        NGINX_PODS=$(kubectl get pods -n todo-app -l app=todo-nginx -o jsonpath='{.items[*].metadata.name}')
        
        if [ -z "$NGINX_PODS" ]; then
            echo "❌ No nginx pods found!"
            exit 1
        fi
        
        echo "📋 Nginx Pods: $NGINX_PODS"
        echo ""
        echo "🎯 Sending 20 requests to test load distribution..."
        
        # Test load balancing
        for i in {1..20}; do
            # Send request and capture response headers
            RESPONSE=$(curl -s -I "http://localhost:8080/api/todos" 2>/dev/null || echo "Connection failed")
            
            # Extract pod info from response (if available)
            if echo "$RESPONSE" | grep -q "X-Pod-Name"; then
                POD_NAME=$(echo "$RESPONSE" | grep "X-Pod-Name" | cut -d: -f2 | tr -d ' ')
                echo "📤 Request $i → Pod: $POD_NAME"
            else
                echo "📤 Request $i → Load balanced"
            fi
            
            sleep 0.5
        done
        
        echo ""
        echo "✅ Load balancing test completed!"
        ;;
        
    "test-rate-limiting")
        echo "🚫 Testing Rate Limiting..."
        echo "This will send rapid requests to test rate limiting"
        
        echo "🎯 Sending 150 requests rapidly (should hit rate limit)..."
        
        SUCCESS_COUNT=0
        RATE_LIMITED_COUNT=0
        
        for i in {1..150}; do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/todos" 2>/dev/null || echo "000")
            
            if [ "$HTTP_CODE" = "200" ]; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                echo -n "✅"
            elif [ "$HTTP_CODE" = "429" ]; then
                RATE_LIMITED_COUNT=$((RATE_LIMITED_COUNT + 1))
                echo -n "🚫"
            else
                echo -n "❌"
            fi
            
            if [ $((i % 10)) -eq 0 ]; then
                echo ""
            fi
        done
        
        echo ""
        echo "📊 Rate Limiting Test Results:"
        echo "   Successful requests: $SUCCESS_COUNT"
        echo "   Rate limited requests: $RATE_LIMITED_COUNT"
        echo "   Total requests: 150"
        ;;
        
    "test-session-affinity")
        echo "🍪 Testing Session Affinity..."
        echo "This will test if requests from the same IP go to the same pod"
        
        echo "🎯 Testing session affinity with multiple requests..."
        
        # Get client IP
        CLIENT_IP=$(curl -s "https://api.ipify.org" 2>/dev/null || echo "127.0.0.1")
        echo "📍 Client IP: $CLIENT_IP"
        
        echo ""
        echo "🔄 Sending 10 requests to test session affinity..."
        
        for i in {1..10}; do
            RESPONSE=$(curl -s -I "http://localhost:8080/api/todos" 2>/dev/null || echo "Connection failed")
            
            if echo "$RESPONSE" | grep -q "Set-Cookie"; then
                COOKIE=$(echo "$RESPONSE" | grep "Set-Cookie" | head -1)
                echo "📤 Request $i → Cookie: ${COOKIE:0:50}..."
            else
                echo "📤 Request $i → No cookie set"
            fi
            
            sleep 1
        done
        
        echo ""
        echo "✅ Session affinity test completed!"
        ;;
        
    "test-health-checks")
        echo "🏥 Testing Health Checks..."
        echo "This will test the health check endpoints"
        
        echo "🎯 Testing health endpoints..."
        
        # Test nginx health
        echo "🔍 Testing nginx health endpoint..."
        NGINX_HEALTH=$(curl -s "http://localhost:8080/health" 2>/dev/null || echo "Failed")
        echo "   Nginx Health: $NGINX_HEALTH"
        
        # Test backend health
        echo "🔍 Testing backend health endpoint..."
        BACKEND_HEALTH=$(curl -s "http://localhost:8080/actuator/health" 2>/dev/null || echo "Failed")
        if echo "$BACKEND_HEALTH" | grep -q "UP"; then
            echo "   Backend Health: ✅ UP"
        else
            echo "   Backend Health: ❌ DOWN"
        fi
        
        echo ""
        echo "✅ Health check test completed!"
        ;;
        
    "monitor")
        echo "📊 Monitoring Load Balancing in Real-time..."
        echo "Press Ctrl+C to stop monitoring"
        
        while true; do
            clear
            echo "🔄 Load Balancing Monitor - $(date)"
            echo "========================================="
            
            echo "🔍 Nginx Pods:"
            kubectl get pods -n todo-app -l app=todo-nginx -o wide
            
            echo ""
            echo "🌐 Services:"
            kubectl get services -n todo-app
            
            echo ""
            echo "📈 Pod Resource Usage:"
            kubectl top pods -n todo-app -l app=todo-nginx 2>/dev/null || echo "Metrics server not available"
            
            echo ""
            echo "📝 Recent Events:"
            kubectl get events -n todo-app --sort-by='.lastTimestamp' | grep -E "(nginx|ingress)" | tail -5
            
            sleep 10
        done
        ;;
        
    "cleanup")
        echo "🧹 Cleaning up load balancing deployment..."
        kubectl delete -k k8s/overlays/$ENVIRONMENT/
        echo "✅ Cleanup completed!"
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo ""
        echo "Available actions:"
        echo "  status           - Show current load balancing status"
        echo "  deploy           - Deploy to specified environment"
        echo "  test-load-balancing - Test load distribution"
        echo "  test-rate-limiting   - Test rate limiting"
        echo "  test-session-affinity - Test session affinity"
        echo "  test-health-checks    - Test health endpoints"
        echo "  monitor          - Real-time monitoring"
        echo "  cleanup          - Remove deployment"
        echo ""
        echo "Usage: $0 [environment] [action]"
        echo "Environments: development, staging, production"
        exit 1
        ;;
esac
