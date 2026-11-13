FROM clojure:temurin-21-lein AS build
WORKDIR /app
COPY project.clj /app/
RUN lein deps
COPY src /app/src
RUN mv "$(lein uberjar | sed -n 's/^Created \(.*standalone\.jar\)/\1/p')" /app/benchmark.jar

FROM eclipse-temurin:21-jre
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/benchmark.jar /app/benchmark.jar
COPY memory-wrapper.sh /app/memory-wrapper.sh
ENTRYPOINT ["/app/memory-wrapper.sh", "java", "-jar", "/app/benchmark.jar"]
CMD []
