FROM oven/bun:1

COPY . /app
RUN bun install --production --frozen-lockfile --cwd /app
ENTRYPOINT ["bun", "run", "/app/main.mjs"]
CMD []
