FROM alpine:3.21

RUN apk add --no-cache build-base lua5.1-dev luarocks5.1 luajit pcre-dev \
 && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time \
 && luarocks-5.1 install jsonschema && luarocks-5.1 install lua-cjson \
 && luarocks-5.1 show jsonschema | sed -n 's/^jsonschema \([^ ]*\) .*/\1/p' | head -1 > /jsonschema-version

COPY . /app
ENTRYPOINT ["/app/memory-wrapper.sh", "luajit", "/app/main.lua"]
CMD []
