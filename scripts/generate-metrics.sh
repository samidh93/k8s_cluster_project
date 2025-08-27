#!/bin/bash

# Generate sample metrics data for Todo app monitoring
echo "🚀 Generating sample metrics data for Todo app..."

# Base URL for the Todo app
BASE_URL="http://localhost:8080"

# Function to create a todo
create_todo() {
    local title="$1"
    local description="$2"
    local priority="$3"
    
    echo "Creating todo: $title"
    curl -s -X POST "$BASE_URL/api/todos" \
        -H "Content-Type: application/json" \
        -d "{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"priority\": \"$priority\",
            \"completed\": false
        }" > /dev/null
    
    sleep 1
}

# Function to complete a todo
complete_todo() {
    local id="$1"
    echo "Completing todo ID: $id"
    curl -s -X PUT "$BASE_URL/api/todos/$id" \
        -H "Content-Type: application/json" \
        -d "{
            \"completed\": true
        }" > /dev/null
    
    sleep 1
}

# Function to delete a todo
delete_todo() {
    local id="$1"
    echo "Deleting todo ID: $id"
    curl -s -X DELETE "$BASE_URL/api/todos/$id" > /dev/null
    
    sleep 1
}

# Function to simulate user activity
simulate_user_activity() {
    echo "Simulating user activity..."
    
    # Create some todos
    create_todo "Complete Project Setup" "Finish the initial project configuration" "HIGH"
    create_todo "Write Documentation" "Create comprehensive project documentation" "MEDIUM"
    create_todo "Test Features" "Run through all application features" "HIGH"
    create_todo "Deploy to Production" "Deploy the application to production environment" "LOW"
    create_todo "Monitor Performance" "Set up performance monitoring and alerting" "MEDIUM"
    
    # Complete some todos
    complete_todo 1
    complete_todo 3
    
    # Delete one todo
    delete_todo 5
    
    # Create more todos
    create_todo "Optimize Database" "Improve database query performance" "HIGH"
    create_todo "Add Unit Tests" "Increase test coverage to 90%" "MEDIUM"
    create_todo "Security Review" "Conduct security audit and fix vulnerabilities" "HIGH"
    
    # Complete more todos
    complete_todo 6
    complete_todo 7
    
    echo "✅ Sample metrics data generated!"
}

# Check if the app is running
if ! curl -s "$BASE_URL/actuator/health" > /dev/null; then
    echo "❌ Todo app is not running at $BASE_URL"
    echo "Please start the app first: kubectl port-forward -n todo-app service/todo-nginx 8080:80"
    exit 1
fi

# Generate metrics
simulate_user_activity

echo ""
echo "📊 Metrics data has been generated!"
echo "Check your Grafana dashboards at: http://localhost:3000"
echo "Username: admin, Password: admin"
echo ""
echo "Available dashboards:"
echo "- Todo App - Business Intelligence Dashboard"
echo "- Todo App - Performance Monitoring"
echo "- Todo App - Operational Dashboard"
