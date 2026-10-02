FROM swift:6.4

RUN apt-get update && apt-get install -y --no-install-recommends time jq pkg-config && rm -rf /var/lib/apt/lists/*

# The C library, which the Swift package uses on Linux through its pkg-config file. The repository's releases: Docker
# downloads the list on every build and reuses the layers below only while it is unchanged, so a new release of the
# C library (tagged capi-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("capi-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && name="corvus-json-schema-${tag#capi-v}-$(uname -m)-unknown-linux-gnu" \
 && curl -sSfL "https://github.com/corvus-dotnet/Corvus.JsonSchema/releases/download/$tag/$name.tar.gz" | tar -xz -C /opt \
 && mv "/opt/$name" /opt/corvus-json-schema
ENV PKG_CONFIG_PATH=/opt/corvus-json-schema/lib/pkgconfig LD_LIBRARY_PATH=/opt/corvus-json-schema/lib

# The Swift package's tags: as above, a new release is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/corvus-json-schema-swift/tags /tmp/swift-tags.json

COPY . /app
RUN cd /app && swift build -c release \
 && jq -r '.pins[] | select(.identity == "corvus-json-schema-swift") | .state.version' Package.resolved > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/.build/release/corvus_swift_benchmark"]
CMD []
