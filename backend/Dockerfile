# Stage 1: Build Java Spring Boot JAR
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime Image
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/*.jar app.jar

ENV STORAGE_LOCAL_DIR=/app/storage
ENV AI_SERVICE_URL=http://ai-service:8000
ENV DB_HOST=postgres
ENV DB_PORT=5432
ENV DB_NAME=projectvault
ENV PORT=8081

EXPOSE 8081

ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
