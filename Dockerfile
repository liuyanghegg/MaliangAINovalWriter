FROM maven:3.9-eclipse-temurin-21 AS builder
LABEL "language"="java"
LABEL "framework"="spring-boot"

WORKDIR /build
COPY . .

# Configure Maven with Aliyun mirrors for faster downloads in China
RUN mkdir -p /root/.m2 && \
    cat > /root/.m2/settings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
    <mirror>
      <id>aliyun-spring</id>
      <mirrorOf>spring</mirrorOf>
      <url>https://maven.aliyun.com/repository/spring</url>
    </mirror>
  </mirrors>
</settings>
EOF

# Build the application
RUN mvn clean package -DskipTests -f AINovalServer/pom.xml

FROM eclipse-temurin:21-jre

ENV TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SPRING_PROFILES_ACTIVE=prod \
    JVM_XMS=512m \
    JVM_XMX=1024m \
    MONGODB_URI=mongodb://mongo:kIxUV2418mr70ZRB3uT5vMHDC6ij9KzX@cgk1.clusters.zeabur.com:25586

# Fix JDK 21 reflective access for BigDecimal in Spring Data Mongo
ENV JAVA_TOOL_OPTIONS="--add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED"

WORKDIR /app

# Create web directory
RUN mkdir -p /app/web

# Copy built JAR from builder stage
COPY --from=builder /build/AINovalServer/target/ai-novel-server-*.jar /app/ainoval-server.jar

# Copy web assets from builder stage (if they exist)
COPY --from=builder /build/deploy/dist/web/ /app/web/

EXPOSE 18080

# Start the application with all necessary JVM options
CMD sh -c "java -Xms${JVM_XMS} -Xmx${JVM_XMX} \
    -Dfile.encoding=UTF-8 \
    -Dspring.web.resources.static-locations=file:/app/web/ \
    -Dspring.data.mongodb.uri=${MONGODB_URI} \
    -jar /app/ainoval-server.jar"


