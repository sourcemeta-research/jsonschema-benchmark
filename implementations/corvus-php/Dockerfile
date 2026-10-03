FROM php:8.4-cli-alpine3.21

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time

# The package's versions on Packagist: Docker downloads them on every build and reuses the layers below only while
# they are unchanged, so a new corvus-dotnet/corvus-json-schema release is picked up by the next build.
ADD https://repo.packagist.org/p2/corvus-dotnet/corvus-json-schema.json /tmp/corvus-packagist.json

# The latest release's prebuilt extension for this PHP (8.4, NTS, musl, the platform's architecture): the archive PIE
# would install, downloaded directly from the release. PIE finds it through GitHub's API, unauthenticated, which shared
# CI runners can find rate-limited.
COPY . /app
RUN apk add --no-cache --virtual .fetch curl jq unzip \
 && version=$(jq -r '[.packages["corvus-dotnet/corvus-json-schema"][].version | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))] | sort_by(split(".") | map(tonumber)) | last' /tmp/corvus-packagist.json) \
 && name="php_corvus_json_schema-${version}_php$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')-$(uname -m | sed 's/aarch64/arm64/')-linux-musl$(php -r 'echo PHP_ZTS ? "-zts" : "";')" \
 && curl -sSfL -o /tmp/extension.zip "https://github.com/corvus-dotnet/corvus-json-schema-php/releases/download/${version}/${name}.zip" \
 && unzip -q /tmp/extension.zip -d /tmp/extension \
 && cp /tmp/extension/corvus_json_schema.so "$(php-config --extension-dir)/" \
 && docker-php-ext-enable corvus_json_schema \
 && rm -rf /tmp/extension /tmp/extension.zip \
 && apk del .fetch \
 && php -r 'echo phpversion("corvus_json_schema");' > /app/corvus-version
# No memory limit, as for Opis (the composer image sets none): the larger corpora need more than the default 128 MB.
ENTRYPOINT ["/app/memory-wrapper.sh", "php", "-d", "memory_limit=-1", "/app/main.php"]
CMD []
