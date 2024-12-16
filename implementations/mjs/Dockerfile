FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.2_2.13.10 AS builder

WORKDIR /app

# Build the project to cache the dependencies
COPY build.sbt /app
COPY project /app/project
RUN sbt assembly

# Add the app and build again
COPY Benchmark.scala /app
RUN sbt assembly

ENTRYPOINT ["java", "-jar", "/app/target/scala-2.13/benchmarkMjs.jar"]
CMD []
