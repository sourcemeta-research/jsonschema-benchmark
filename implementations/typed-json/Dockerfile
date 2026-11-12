FROM unisonlang/unison:1.3.0 AS build
COPY --chown=unison:unison build.md benchmark.u /benchmark/
WORKDIR /benchmark
# Installs typed-json, compiles benchmark.main to benchmark.uc, and fails the build if any stanza fails.
RUN ucm transcript build.md

FROM unisonlang/unison:1.3.0
USER root
RUN apt-get update && apt-get install -y --no-install-recommends time && rm -rf /var/lib/apt/lists/*
USER unison
COPY --from=build /benchmark/benchmark.uc /app/benchmark.uc
COPY memory-wrapper.sh run.sh /app/
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/run.sh"]
CMD []
