#!/bin/bash

API_URL="http://54.224.108.46:8080/api/tasks"

echo "🚀 Inserting sample tasks..."

# Array of sample tasks
declare -a tasks=(
  '{"title": "Implement user authentication API", "description": "Create JWT-based authentication system with refresh tokens", "priority": "HIGH", "completed": false}'
  '{"title": "Design user registration flow", "description": "Create wireframes and mockups for user registration process", "priority": "MEDIUM", "completed": true}'
  '{"title": "Fix payment gateway timeout issue", "description": "Payment processing fails after 30 seconds, investigate and fix", "priority": "HIGH", "completed": false}'
  '{"title": "Test checkout process on mobile", "description": "Comprehensive testing of mobile checkout flow across devices", "priority": "HIGH", "completed": false}'
  '{"title": "Deploy staging environment", "description": "Set up staging server with latest code and database migration", "priority": "HIGH", "completed": false}'
  '{"title": "Update API documentation", "description": "Document new authentication endpoints and payment APIs", "priority": "MEDIUM", "completed": false}'
  '{"title": "Security audit - Authentication module", "description": "Perform security review of authentication implementation", "priority": "HIGH", "completed": false}'
  '{"title": "Prepare demo for client meeting", "description": "Create presentation and demo environment for client showcase", "priority": "HIGH", "completed": false}'
  '{"title": "Database performance optimization", "description": "Optimize slow queries and add proper indexing", "priority": "MEDIUM", "completed": false}'
  '{"title": "Recruit senior frontend developer", "description": "Interview and hire experienced React developer for team expansion", "priority": "MEDIUM", "completed": false}'
)

# Insert each task
for i in "${!tasks[@]}"; do
  echo "Inserting task $((i+1))/10..."
  curl -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "${tasks[$i]}" \
    -s -o /dev/null
  sleep 0.5
done

echo "✅ All sample tasks inserted!"
echo "📊 View tasks at: http://localhost:3001"
