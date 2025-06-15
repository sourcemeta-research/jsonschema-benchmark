FROM rust:1.84.1-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time
RUN apk add --no-cache musl-dev

COPY . /app
RUN cargo build --release --manifest-path /app/Cargo.toml
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/target/release/boon_benchmark"]
CMD []
