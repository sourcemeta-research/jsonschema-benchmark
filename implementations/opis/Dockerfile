FROM composer:2.8.5

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

COPY . /app
RUN composer install
ENTRYPOINT ["/app/memory-wrapper.sh", "composer", "-d", "/app", "benchmark"]
CMD []
