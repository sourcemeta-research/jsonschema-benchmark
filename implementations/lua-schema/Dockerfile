FROM alpine:3.21

RUN apk add --no-cache build-base lua5.4 lua5.4-dev luarocks5.4 pcre2-dev \
 && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time \
 && luarocks-5.4 install lua-schema && luarocks-5.4 install dkjson && luarocks-5.4 install luaposix \
 && luarocks-5.4 install lrexlib-pcre2 \
 && luarocks-5.4 show lua-schema | sed -n 's/^lua-schema \([^ ]*\) .*/\1/p' | head -1 > /lua-schema-version

COPY . /app
ENTRYPOINT ["/app/memory-wrapper.sh", "lua5.4", "/app/main.lua"]
CMD []
