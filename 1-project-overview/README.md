# Project Overview - Task Management API

## Project Description

A production-ready **Task Management REST API** built with modern DevOps practices, demonstrating the complete journey from code to cloud deployment.

## Business Requirements

### **What is this service?**
A microservice that manages tasks for project management, allowing users to create, read, update, and delete tasks with proper status tracking and assignment capabilities.

### **Why build this service?**
- **Real-world application**: Demonstrates practical microservice patterns
- **Interview preparation**: Covers all DevOps tools and practices
- **Production readiness**: Implements enterprise-grade solutions
- **Scalability**: Designed to handle high traffic loads

## Architecture Overview

┌─────────────────────────────────────────────────────────────────┐
│                        PRODUCTION ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐    ┌─────────────┐         │
│  │   GitHub    │     │   GitHub    │    │   Amazon    │         │
│  │ Repository  │───▶│   Actions   │───▶│     ECR     │         │
│  │             │     │    (CI)     │    │             │         │
│  └─────────────┘     └─────────────┘    └─────────────┘         │
│                                                │                │
│                                                ▼                │
│  ┌─────────────┐     ┌─────────────┐    ┌─────────────┐         │
│  │     EKS     │◀───│   ArgoCD    │◀───│ Config Repo │         │
│  │   Cluster   │     │    (CD)     │    │             │         │
│  │             │     │             │    │             │         │
│  └─────────────┘     └─────────────┘    └─────────────┘         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    EKS CLUSTER                          │    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ Task API    │  │   MySQL     │  │ Monitoring  │      │    │
│  │  │   Pods      │  │ Database    │  │   Stack     │      │    │
│  │  │             │  │             │  │             │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ Prometheus  │  │   Grafana   │  │     ELK     │      │    │
│  │  │             │  │             │  │    Stack    │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘


## API Specification

### **Core Endpoints**
```
GET    /api/v1/tasks           - List all tasks
GET    /api/v1/tasks/{id}      - Get specific task
POST   /api/v1/tasks           - Create new task
PUT    /api/v1/tasks/{id}      - Update existing task
DELETE /api/v1/tasks/{id}      - Delete task
GET    /api/v1/tasks/status/{status} - Filter by status
GET    /api/v1/tasks/assignee/{email} - Filter by assignee
```

### **Health & Monitoring Endpoints**
```
GET    /actuator/health        - Application health
GET    /actuator/metrics       - Prometheus metrics
GET    /actuator/info          - Application info
GET    /actuator/prometheus    - Metrics endpoint
```

### **Task Data Model**
```json
{
  "id": 1,
  "title": "Implement CI/CD Pipeline",
  "description": "Setup GitHub Actions with ArgoCD for automated deployment",
  "status": "IN_PROGRESS",
  "priority": "HIGH",
  "assignee": "devops.engineer@company.com",
  "tags": ["devops", "automation", "kubernetes"],
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T14:20:00Z",
  "dueDate": "2024-01-25T18:00:00Z"
}
```

### **Status Values**
- `TODO` - Task created but not started
- `IN_PROGRESS` - Task currently being worked on
- `REVIEW` - Task completed, awaiting review
- `DONE` - Task completed and approved
- `BLOCKED` - Task cannot proceed due to dependencies

### **Priority Values**
- `LOW` - Nice to have features
- `MEDIUM` - Standard priority tasks
- `HIGH` - Important business requirements
- `CRITICAL` - Production issues, urgent fixes

## Technology Stack

### **Application Layer**
- **Language**: Java 17 (LTS)
- **Framework**: Spring Boot 3.2.x
- **Database**: MySQL 8.0
- **Build Tool**: Maven 3.9.x
- **Testing**: JUnit 5, Mockito, TestContainers

### **Infrastructure Layer**
- **Cloud Provider**: AWS
- **Container Registry**: Amazon ECR
- **Orchestration**: Amazon EKS (Kubernetes 1.28)
- **Database**: Amazon RDS MySQL (Multi-AZ)
- **Load Balancer**: AWS Application Load Balancer

### **DevOps Tools**
- **Version Control**: Git with GitHub
- **CI Pipeline**: GitHub Actions
- **CD Pipeline**: ArgoCD (GitOps)
- **Container Runtime**: Docker
- **Infrastructure as Code**: CloudFormation

### **Monitoring & Observability**
- **Metrics**: Prometheus + Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Distributed Logging**: Loki
- **Load Testing**: Locust, K6
- **APM**: Micrometer (Spring Boot Actuator)

## Development Environments

### **Local Development**
- **Java 17** with Maven
- **MySQL** via Docker Compose
- **IDE**: IntelliJ IDEA / VS Code
- **Testing**: Embedded H2 database

### **Development Environment**
- **EKS Cluster**: Single node group
- **Database**: RDS MySQL (Single AZ)
- **Monitoring**: Basic Prometheus setup
- **Domain**: `dev-api.company.com`

### **Staging Environment**
- **EKS Cluster**: Multi-node, single AZ
- **Database**: RDS MySQL (Single AZ with backups)
- **Monitoring**: Full observability stack
- **Domain**: `staging-api.company.com`

### **Production Environment**
- **EKS Cluster**: Multi-node, Multi-AZ
- **Database**: RDS MySQL (Multi-AZ with read replicas)
- **Monitoring**: Complete observability + alerting
- **Domain**: `api.company.com`

## Non-Functional Requirements

### **Performance**
- **Response Time**: < 200ms for 95th percentile
- **Throughput**: Handle 1000 requests/second
- **Availability**: 99.9% uptime SLA
- **Scalability**: Auto-scale from 2 to 50 pods

### **Security**
- **Authentication**: JWT tokens
- **Authorization**: Role-based access control
- **Data Encryption**: TLS 1.3 in transit, AES-256 at rest
- **Network Security**: VPC with private subnets
- **Container Security**: Non-root user, minimal base image

### **Reliability**
- **Database Backups**: Daily automated backups
- **Disaster Recovery**: Multi-AZ deployment
- **Health Checks**: Liveness and readiness probes
- **Circuit Breakers**: Resilience patterns

### **Compliance**
- **Logging**: Audit trail for all operations
- **Data Retention**: 7 years for compliance
- **Privacy**: GDPR compliant data handling
- **Security Scanning**: Automated vulnerability scans

## Project Phases & Timeline

### **Phase 1: Foundation (Week 1)**
- ✅ Setup development environment
- ✅ Implement REST API with Spring Boot
- ✅ Add MySQL database integration
- ✅ Write unit and integration tests
- ✅ Local testing and validation

### **Phase 2: Containerization (Week 2)**
- ✅ Create optimized Dockerfile
- ✅ Setup Docker Compose for local development
- ✅ Implement container security best practices
- ✅ Container image scanning and optimization

### **Phase 3: Infrastructure (Week 3)**
- ✅ Create CloudFormation templates
- ✅ Setup VPC with proper networking
- ✅ Deploy EKS cluster
- ✅ Configure ECR repository

### **Phase 4: Kubernetes (Week 4)**
- ✅ Write Kubernetes manifests
- ✅ Implement ConfigMaps and Secrets
- ✅ Setup auto-scaling and load balancing
- ✅ Deploy to EKS cluster

### **Phase 5: CI/CD (Week 5)**
- ✅ Create GitHub Actions pipeline
- ✅ Setup ArgoCD for GitOps deployment
- ✅ Implement security scanning
- ✅ Multi-environment deployment strategy

### **Phase 6: Monitoring (Week 6)**
- ✅ Deploy Prometheus and Grafana
- ✅ Setup ELK stack for logging
- ✅ Implement alerting rules
- ✅ Load testing with Locust

## Success Criteria

### **Technical Metrics**
- ✅ API response time < 200ms
- ✅ 99.9% availability
- ✅ Zero-downtime deployments
- ✅ Automated scaling based on load
- ✅ Complete test coverage > 80%

### **DevOps Metrics**
- ✅ Deployment frequency: Multiple times per day
- ✅ Lead time for changes: < 1 hour
- ✅ Mean time to recovery: < 15 minutes
- ✅ Change failure rate: < 5%

### **Business Metrics**
- ✅ Support 10,000+ tasks
- ✅ Handle 100+ concurrent users
- ✅ Process 1M+ API requests/day
- ✅ 24/7 availability

## Learning Outcomes

After completing this project, you will have hands-on experience with:

### **Development Skills**
- REST API design and implementation
- Database design and optimization
- Test-driven development
- Code quality and security practices

### **DevOps Skills**
- Container orchestration with Kubernetes
- CI/CD pipeline implementation
- Infrastructure as Code
- GitOps deployment strategies

### **Cloud Skills**
- AWS services integration
- Auto-scaling and load balancing
- Security and compliance
- Cost optimization

### **Monitoring Skills**
- Metrics collection and visualization
- Centralized logging
- Alerting and incident response
- Performance testing and optimization

This project serves as a comprehensive portfolio piece demonstrating enterprise-level DevOps practices and prepares you for senior DevOps engineer interviews.
