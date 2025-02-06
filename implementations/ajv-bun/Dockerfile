FROM oven/bun:1.2.2

COPY . /app
RUN bun install --production --frozen-lockfile --cwd /app
ENTRYPOINT ["bun", "run", "/app/main.mjs"]
CMD []
