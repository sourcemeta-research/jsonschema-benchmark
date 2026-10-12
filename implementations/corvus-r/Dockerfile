# Corvus.JsonSchema's R package (corvusjsonschema), which validates R values in place with the corvus-json-schema
# Rust crate. R-universe serves the package as source for Linux, so the image has a Rust toolchain to build it.
FROM rocker/r-ver:4

RUN apt-get update && apt-get install -y --no-install-recommends time curl ca-certificates build-essential \
 && rm -rf /var/lib/apt/lists/*
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

# The package's entry on R-universe: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new release of corvusjsonschema is picked up by the next build.
ADD https://corvus-dotnet.r-universe.dev/api/packages/corvusjsonschema /tmp/corvus-latest.json

COPY . /app
RUN Rscript -e 'install.packages(c("corvusjsonschema", "jsonlite"), repos = c("https://corvus-dotnet.r-universe.dev", "https://cloud.r-project.org"))' \
 && Rscript -e 'cat(as.character(packageVersion("corvusjsonschema")))' > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "Rscript", "--vanilla", "/app/main.R"]
CMD []
