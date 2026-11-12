FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.2_2.13.10 AS builder
WORKDIR /opt/benchmark
COPY build.sbt /opt/benchmark/
COPY project /opt/benchmark/project
COPY src /opt/benchmark/src
RUN sbt assembly

FROM eclipse-temurin:21-jre
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/benchmark/target/scala-*/benchmark.jar /app/benchmark.jar
COPY memory-wrapper.sh /app/memory-wrapper.sh
ENTRYPOINT ["/app/memory-wrapper.sh", "java", "-jar", "/app/benchmark.jar"]
CMD []
