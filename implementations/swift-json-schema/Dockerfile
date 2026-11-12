FROM swift:6.4

RUN apt-get update && apt-get install -y --no-install-recommends time jq && rm -rf /var/lib/apt/lists/*

# The package's tags: Docker downloads them on every build and reuses the layers below only while they are
# unchanged, so a new release is picked up by the next build.
ADD https://api.github.com/repos/ajevans99/swift-json-schema/tags /tmp/swift-json-schema-tags.json

COPY . /app
RUN cd /app && swift build -c release \
 && jq -r '.pins[] | select(.identity == "swift-json-schema") | .state.version' Package.resolved > /app/swift-json-schema-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/.build/release/swift_json_schema_benchmark"]
CMD []
