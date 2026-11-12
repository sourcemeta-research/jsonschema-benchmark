FROM maven:3.9-eclipse-temurin-25 AS build
COPY pom.xml /app/pom.xml
COPY src /app/src
RUN cd /app && mvn -B -q -ntp package

FROM eclipse-temurin:25-jre
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/target/bench.jar /app/bench.jar
COPY --from=build /app/target/lib /app/lib
COPY memory-wrapper.sh /app/memory-wrapper.sh
ENTRYPOINT ["/app/memory-wrapper.sh", "java", "-cp", "/app/bench.jar:/app/lib/*", "Main"]
CMD []
