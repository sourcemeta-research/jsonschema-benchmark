FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.2_2.13.10 AS builder
WORKDIR /opt/benchmark
COPY build.sbt /opt/benchmark/
COPY project /opt/benchmark/project
COPY src /opt/benchmark/src
# The 2020-12 meta-schemas, which the library does not bundle, for schemas that refer to them.
RUN mkdir -p /opt/benchmark/src/main/resources/metaschemas \
 && curl -sSfL https://json-schema.org/draft/2020-12/schema -o /opt/benchmark/src/main/resources/metaschemas/schema.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/core -o /opt/benchmark/src/main/resources/metaschemas/meta_core.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/applicator -o /opt/benchmark/src/main/resources/metaschemas/meta_applicator.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/unevaluated -o /opt/benchmark/src/main/resources/metaschemas/meta_unevaluated.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/validation -o /opt/benchmark/src/main/resources/metaschemas/meta_validation.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/meta-data -o /opt/benchmark/src/main/resources/metaschemas/meta_meta-data.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/format-annotation -o /opt/benchmark/src/main/resources/metaschemas/meta_format-annotation.json \
 && curl -sSfL https://json-schema.org/draft/2020-12/meta/content -o /opt/benchmark/src/main/resources/metaschemas/meta_content.json
RUN sbt assembly

FROM eclipse-temurin:21-jre
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/benchmark/target/scala-*/benchmark.jar /app/benchmark.jar
COPY memory-wrapper.sh /app/memory-wrapper.sh
ENTRYPOINT ["/app/memory-wrapper.sh", "java", "-jar", "/app/benchmark.jar"]
CMD []
