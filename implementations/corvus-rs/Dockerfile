FROM rust:1.90-alpine3.22

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time
RUN apk add --no-cache musl-dev

# The crate's index entry: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new corvus-json-schema release is picked up by the next build.
ADD https://index.crates.io/co/rv/corvus-json-schema /tmp/corvus-index

COPY . /app
RUN cargo update --manifest-path /app/Cargo.toml --package corvus-json-schema \
 && cargo build --release --locked --manifest-path /app/Cargo.toml \
 && sed -n '/^name = "corvus-json-schema"$/{n;s/^version = "\(.*\)"$/\1/p;}' /app/Cargo.lock > /app/corvus-version
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/target/release/corvus_rs_benchmark"]
CMD []
