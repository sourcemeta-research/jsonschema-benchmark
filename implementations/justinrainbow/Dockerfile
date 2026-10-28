FROM php:8.4-cli-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

COPY --from=composer:2.8.5 /usr/bin/composer /usr/bin/composer
COPY . /app
RUN composer --working-dir=/app install --no-dev --classmap-authoritative
# No memory limit, as for Opis (the composer image sets none): the larger corpora need more than the default 128 MB.
ENTRYPOINT ["/app/memory-wrapper.sh", "php", "-d", "memory_limit=-1", "-d", "display_errors=stderr", "/app/main.php"]
CMD []
