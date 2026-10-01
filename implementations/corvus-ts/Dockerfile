FROM node:23.7.0-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# The package's latest release: Docker downloads it on every build and reuses the layers below only while it is
# unchanged, so a new @corvus-dotnet/json-schema release is picked up by the next build.
ADD https://registry.npmjs.org/@corvus-dotnet/json-schema/latest /tmp/corvus-latest.json

COPY . /app
RUN npm ci --prefix /app \
 && npm install --prefix /app --no-save @corvus-dotnet/json-schema@latest
ENTRYPOINT ["/app/memory-wrapper.sh", "node", "/app/main.mjs"]
CMD []
