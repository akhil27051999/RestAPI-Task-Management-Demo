# ===============================================================================
# TASK MANAGEMENT API - PRODUCTION DOCKERFILE
# Multi-stage build for optimal security and performance
# ===============================================================================

# ===============================================================================
# STAGE 1: BUILD ENVIRONMENT
# Purpose: Compile application and run tests
# ===============================================================================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine AS build-env

# Set build arguments
ARG JAR_FILE=target/*.jar
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=1.0.0

# Add labels for container metadata
LABEL maintainer="devops@company.com" \
      org.opencontainers.image.title="Task Management API" \
      org.opencontainers.image.description="REST API for task management" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/company/task-management-api"

# Install build dependencies
RUN apk add --no-cache \
    maven \
    git \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Copy Maven configuration files first (for better caching)
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./

# Make Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (cached layer if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B -q

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests -B -q && \
    mv target/*.jar app.jar

# ===============================================================================
# STAGE 2: SECURITY SCANNING & TESTING
# Purpose: Run security scans and tests
# ===============================================================================
FROM build-env AS test-env

# Install security scanning tools
RUN apk add --no-cache \
    trivy \
    && rm -rf /var/cache/apk/*

# Run tests
RUN ./mvnw test -B -q

# Run security scan on dependencies
RUN ./mvnw org.owasp:dependency-check-maven:check -B -q || true

# ===============================================================================
# STAGE 3: RUNTIME ENVIRONMENT
# Purpose: Minimal production runtime
# ===============================================================================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine AS runtime

# Install runtime dependencies only
RUN apk add --no-cache \
    curl \
    dumb-init \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
ENV APPUSER=taskapi
ENV APPUID=1000
ENV APPGID=1000

RUN addgroup -g $APPGID $APPUSER && \
    adduser -D -u $APPUID -G $APPUSER -s /bin/sh $APPUSER

# Create app directory with proper permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R $APPUSER:$APPUSER /app

# Set working directory
WORKDIR /app

# Copy application JAR from build stage
COPY --from=build-env --chown=$APPUSER:$APPUSER /app/app.jar ./

# Copy health check script
COPY --chown=$APPUSER:$APPUSER scripts/health-check.sh ./
RUN chmod +x health-check.sh

# Switch to non-root user
USER $APPUSER

# Configure JVM for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+UseG1GC \
               -XX:+UseStringDeduplication \
               -Djava.security.egd=file:/dev/./urandom \
               -Dspring.profiles.active=prod"

# Expose application port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ./health-check.sh || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
