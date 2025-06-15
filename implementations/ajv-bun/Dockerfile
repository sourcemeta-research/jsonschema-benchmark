FROM oven/bun:1.2.2

RUN apt-get update -qq \
    && apt-get install -qq --no-install-recommends \
      time \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
RUN bun install --production --frozen-lockfile --cwd /app
ENTRYPOINT ["/app/memory-wrapper.sh", "bun", "run", "/app/main.mjs"]
CMD []
