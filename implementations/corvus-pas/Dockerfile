# Corvus.JsonSchema's Object Pascal evaluator, built with Free Pascal. The package is source: the image takes the
# latest release's archive and compiles the benchmark program with it.
FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends fpc time jq curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# The repository's releases: Docker downloads the list on every build and reuses the layers below only while it is
# unchanged, so a new release of the Object Pascal package (tagged pas-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("pas-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && version=${tag#pas-v} \
 && curl -sSfL "https://github.com/corvus-dotnet/Corvus.JsonSchema/releases/download/$tag/corvus-json-schema-pascal-$version.tar.gz" | tar -xz -C /opt \
 && mv "/opt/corvus-json-schema-$version" /opt/corvus-json-schema \
 && mkdir -p /app && echo "$version" > /app/corvus-version

COPY . /app
RUN mkdir -p /app/build \
 && fpc -O3 -Fu/opt/corvus-json-schema/src -Fi/opt/corvus-json-schema/src -FU/app/build -FE/app /app/main.pas
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/main"]
CMD []
