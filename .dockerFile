# =============================================
# Stage 1: Build stage
# =============================================
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper và pom.xml trước để tận dụng Docker layer cache
COPY mvnw mvnw.cmd ./
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies (cache layer này nếu pom.xml không thay đổi)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build JAR (bỏ qua tests)
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Tạo user không phải root để bảo mật
RUN addgroup -S spring && adduser -S spring -G spring

# Copy JAR từ stage builder
COPY --from=builder /app/target/*.jar app.jar

# Đổi owner cho user spring
RUN chown spring:spring app.jar

USER spring

# Expose port mặc định của Spring Boot
EXPOSE 8080

# Tối ưu JVM cho container
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Chạy ứng dụng
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]


