FROM php:8.4-cli-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# PIE, PHP's extension installer.
ADD --chmod=755 https://github.com/php/pie/releases/latest/download/pie.phar /usr/local/bin/pie

# The package's versions on Packagist: Docker downloads them on every build and reuses the layers below only while
# they are unchanged, so a new corvus-dotnet/corvus-json-schema release is picked up by the next build. PIE installs
# the prebuilt extension for this PHP (8.4, NTS, musl) and enables it.
ADD https://repo.packagist.org/p2/corvus-dotnet/corvus-json-schema.json /tmp/corvus-packagist.json

COPY . /app
RUN pie install corvus-dotnet/corvus-json-schema \
 && php -r 'echo phpversion("corvus_json_schema");' > /app/corvus-version
# No memory limit, as for Opis (the composer image sets none): the larger corpora need more than the default 128 MB.
ENTRYPOINT ["/app/memory-wrapper.sh", "php", "-d", "memory_limit=-1", "/app/main.php"]
CMD []
