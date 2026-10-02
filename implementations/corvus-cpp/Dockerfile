FROM gcc:latest

RUN apt-get update && apt-get install -y --no-install-recommends cmake time jq && rm -rf /var/lib/apt/lists/*

# The repository's releases: Docker downloads the list on every build and reuses the layers below only while it is
# unchanged, so a new release of the C library (tagged capi-v<version>) is picked up by the next build.
ADD https://api.github.com/repos/corvus-dotnet/Corvus.JsonSchema/releases?per_page=100 /tmp/releases.json
RUN tag=$(jq -r '[.[] | select(.tag_name | startswith("capi-v")) | select((.draft or .prerelease) | not)][0].tag_name' /tmp/releases.json) \
 && version=${tag#capi-v} \
 && name="corvus-json-schema-$version-$(uname -m)-unknown-linux-gnu" \
 && curl -sSfL "https://github.com/corvus-dotnet/Corvus.JsonSchema/releases/download/$tag/$name.tar.gz" | tar -xz -C /opt \
 && mv "/opt/$name" /opt/corvus-json-schema \
 && mkdir -p /app && echo "$version" > /app/corvus-version

COPY . /app
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_PREFIX_PATH=/opt/corvus-json-schema \
 && cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/build/corvus_cpp_benchmark"]
CMD []
