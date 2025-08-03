# Frontend Guide

## Overview
React-like dashboard for Task Management API with real-time updates and responsive design.

## Architecture
```
Frontend (Nginx) → API Proxy → Backend (Spring Boot) → MySQL
```

## Local Development

### Prerequisites
- Node.js 18+ (optional for development server)
- Docker & Docker Compose

### Quick Start
```bash
# Using Docker Compose
cd 5-containerization
docker-compose up frontend

# Using Node.js (development)
cd 3-frontend
npm install
npm start
```

## File Structure
```
3-frontend/
├── src/
│   ├── index.html      # Main dashboard
│   ├── css/style.css   # Styling
│   ├── js/script.js    # API interactions
│   └── assets/         # Images/icons
├── Dockerfile          # Container build
├── nginx.conf          # Proxy config
└── package.json        # Dependencies
```

## Features
- **Dashboard**: Task statistics and overview
- **CRUD Operations**: Create, read, update, delete tasks
- **Real-time Updates**: Auto-refresh task list
- **Responsive Design**: Mobile-friendly interface
- **API Integration**: RESTful API communication

## API Endpoints Used
```javascript
GET    /api/tasks           # List all tasks
POST   /api/tasks           # Create new task
PUT    /api/tasks/{id}      # Update task
DELETE /api/tasks/{id}      # Delete task
```

## Configuration

### Environment Variables
```bash
API_BASE_URL=http://app:8080  # Backend URL
```

### Nginx Proxy
```nginx
location /api/ {
    proxy_pass http://app:8080/;
    proxy_set_header Host $host;
}
```

## Deployment

### Docker
```bash
# Build image
docker build -t task-frontend ./3-frontend

# Run container
docker run -p 3001:80 task-frontend
```

### Kubernetes
```bash
kubectl apply -f 7-kubernetes/frontend-deployment.yaml
kubectl apply -f 7-kubernetes/frontend-service.yaml
```

## Monitoring
- **Nginx Status**: `/nginx_status` endpoint
- **Prometheus Metrics**: HTTP requests, response times
- **Grafana Dashboard**: Frontend performance metrics

## Troubleshooting

### Common Issues
1. **API Connection Failed**
   - Check backend service is running
   - Verify nginx proxy configuration

2. **CORS Errors**
   - Ensure CORS headers in nginx.conf
   - Check API endpoint URLs

3. **Static Files Not Loading**
   - Verify file paths in Dockerfile
   - Check nginx document root

### Debug Commands
```bash
# Check container logs
docker logs task-frontend

# Test API connectivity
curl http://localhost:3001/api/tasks

# Verify nginx config
docker exec task-frontend nginx -t
```

## Development Tips
- Use browser dev tools for debugging
- Monitor network tab for API calls
- Check console for JavaScript errors
- Use `docker-compose logs frontend` for container logs
