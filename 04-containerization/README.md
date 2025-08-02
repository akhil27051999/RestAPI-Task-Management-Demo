# Containerization - Docker Setup

Complete containerization strategy for the Task Management API with production-ready Docker configurations.

## Container Strategy Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINERIZATION STRATEGY                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 MULTI-STAGE BUILD                       │    │
│  │                                                         │    │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │    │
│  │  │   Stage 1   │───▶│   Stage 2   │───▶│   Stage 3  │  │    │
│  │  │    Build    │    │    Test     │    │   Runtime   │  │    │
│  │  │             │    │             │    │             │  │    │
│  │  │ Maven Build │    │ Run Tests   │    │ Final Image │  │    │
│  │  │ Dependencies│    │ Security    │    │ Minimal     │  │    │
│  │  └─────────────┘    └─────────────┘    └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                LOCAL DEVELOPMENT                        │    │
│  │                                                         │    │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │    │
│  │  │ Task API    │    │   MySQL     │    │   Redis     │  │    │
│  │  │ Container   │    │ Container   │    │ Container   │  │    │
│  │  │             │    │             │    │             │  │    │
│  │  └─────────────┘    └─────────────┘    └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

# Build & Dependency Management Files

## pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.taskapi</groupId>
    <artifactId>task-management-api</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    <name>task-management-api</name>
    <description>Task Management REST API</description>
    
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- Database -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Metrics -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Test Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>17</source>
                    <target>17</target>
                </configuration>
            </plugin>
            
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.8</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

## Dockerfile
```dockerfile
# Multi-stage build for production
FROM openjdk:17-jdk-slim as builder

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Production stage
FROM openjdk:17-jre-slim

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install curl for health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy JAR from builder stage
COPY --from=builder /app/target/task-management-api-*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# JVM optimization for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

## docker-compose.yml
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: task-management-mysql
    environment:
      MYSQL_ROOT_PASSWORD: password123
      MYSQL_DATABASE: taskdb
      MYSQL_USER: taskuser
      MYSQL_PASSWORD: taskpass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - task-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 30s

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: task-management-api
    environment:
      SPRING_PROFILES_ACTIVE: dev
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/taskdb
      SPRING_DATASOURCE_USERNAME: taskuser
      SPRING_DATASOURCE_PASSWORD: taskpass
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: taskdb
      DB_USERNAME: taskuser
      DB_PASSWORD: taskpass
    ports:
      - "8080:8080"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - task-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  prometheus:
    image: prom/prometheus:latest
    container_name: task-management-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - task-network
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: task-management-grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin123
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - task-network

volumes:
  mysql_data:
  grafana_data:

networks:
  task-network:
    driver: bridge
```

## Additional Required Files

### .dockerignore
```
target/
!target/task-management-api-*.jar
.git
.gitignore
README.md
Dockerfile
docker-compose.yml
.dockerignore
*.md
.mvn/wrapper/maven-wrapper.jar
src/test/
```

### .gitignore
```
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iws
*.iml
*.ipr
.vscode/
.classpath
.project
.settings/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Runtime
*.pid
*.seed
*.pid.lock

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Database
*.db
*.sqlite

# Docker
.docker/
```

## Usage Instructions

### Build Application
```bash
# Build with Maven
mvn clean package

# Build Docker image
docker build -t task-management-api:latest .
```

### Run Locally
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

### Access Application
- **API**: http://localhost:8080/api/tasks
- **Health Check**: http://localhost:8080/actuator/health
- **Metrics**: http://localhost:8080/actuator/prometheus
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)

### Database Access
```bash
# Connect to MySQL
docker exec -it task-management-mysql mysql -u taskuser -p taskdb
```

This configuration provides everything needed for local development and containerized deployment.

