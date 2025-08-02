#!/bin/bash

set -e

echo "🧪 Running comprehensive tests for Task Management API..."

# Set test environment
export SPRING_PROFILES_ACTIVE=test

# Start test database
echo "🗄️ Starting test database..."
docker run -d --name test-mysql \
  -e MYSQL_ROOT_PASSWORD=testpass \
  -e MYSQL_DATABASE=taskdb_test \
  -e MYSQL_USER=testuser \
  -e MYSQL_PASSWORD=testpass \
  -p 3307:3306 \
  mysql:8.0

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 30

# Check if database is ready
until docker exec test-mysql mysqladmin ping -h localhost --silent; do
  echo "Waiting for MySQL..."
  sleep 2
done

echo "✅ Database is ready!"

# Run unit tests
echo "🔬 Running unit tests..."
mvn test -Dtest="*Test"

# Run integration tests
echo "🔗 Running integration tests..."
mvn test -Dtest="*IT" -Dspring.datasource.url=jdbc:mysql://localhost:3307/taskdb_test

# Run all tests with coverage
echo "📊 Running all tests with coverage..."
mvn clean test jacoco:report

# Generate test summary
echo ""
echo "📈 Test Results Summary:"
if [ -f "target/surefire-reports/TEST-*.xml" ]; then
    TOTAL_TESTS=$(grep -h "tests=" target/surefire-reports/TEST-*.xml | sed 's/.*tests="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    FAILED_TESTS=$(grep -h "failures=" target/surefire-reports/TEST-*.xml | sed 's/.*failures="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    ERRORS=$(grep -h "errors=" target/surefire-reports/TEST-*.xml | sed 's/.*errors="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}')
    
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Failed Tests: $FAILED_TESTS"
    echo "  Errors: $ERRORS"
    echo "  Success Rate: $(( (TOTAL_TESTS - FAILED_TESTS - ERRORS) * 100 / TOTAL_TESTS ))%"
fi

# Check code coverage
if [ -f "target/site/jacoco/index.html" ]; then
    echo "📊 Code coverage report generated: target/site/jacoco/index.html"
fi

# Cleanup test database
echo "🧹 Cleaning up test database..."
docker stop test-mysql || true
docker rm test-mysql || true

# Check test results
if [ "$FAILED_TESTS" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
    echo "❌ Some tests failed!"
    exit 1
else
    echo "✅ All tests passed!"
fi

echo ""
echo "🎉 Testing completed successfully!"
echo "📋 Test artifacts:"
echo "  - Test reports: target/surefire-reports/"
echo "  - Coverage report: target/site/jacoco/index.html"
echo "  - Test logs: target/surefire-reports/*.txt"
