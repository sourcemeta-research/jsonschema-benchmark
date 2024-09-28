FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.2_2.13.10 AS builder

WORKDIR /app
COPY Benchmark.scala /app
COPY build.sbt /app
COPY project /app/project
RUN sbt assembly
ENTRYPOINT ["java", "-jar", "/app/target/scala-2.13/benchmarkMjs.jar"]
CMD []
