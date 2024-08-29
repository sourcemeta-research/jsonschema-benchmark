FROM rust:1.80.1-alpine3.20

COPY . /app
RUN cargo build --release --manifest-path /app/Cargo.toml
ENTRYPOINT ["/app/target/release/boon_benchmark"]
CMD []
