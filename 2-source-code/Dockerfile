FROM eclipse-temurin:17-jre-alpine

RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -G appuser

RUN apk add --no-cache curl

WORKDIR /app

COPY target/task-management-api-*.jar app.jar

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
