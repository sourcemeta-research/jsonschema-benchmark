FROM node:26.13.1-alpine3.24

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

COPY . /app
RUN npm ci --prefix /app
ENTRYPOINT ["/app/memory-wrapper.sh", "node", "--disable-warning=ExperimentalWarning", "/app/main.mjs"]
CMD []
