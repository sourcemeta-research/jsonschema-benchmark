# Until @corvus-dotnet/json-schema is published to npm, the image builds it from the Corvus.JsonSchema repository at
# CORVUS_REF.
FROM node:23.7.0-alpine3.21

RUN apk add --no-cache git \
 && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

ARG CORVUS_REPO=https://github.com/corvus-dotnet/Corvus.JsonSchema.git
ARG CORVUS_REF=main
RUN git clone --depth 1 --branch "$CORVUS_REF" "$CORVUS_REPO" /corvus \
 && cd /corvus/src-ts/corvus-json-schema \
 && npm ci \
 && npm run build

COPY . /app
RUN npm install --prefix /app --omit=dev
ENTRYPOINT ["/app/memory-wrapper.sh", "node", "/app/main.mjs"]
CMD []
