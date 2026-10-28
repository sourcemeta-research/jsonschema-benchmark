FROM alpine:3.21.2

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community time
RUN apk add --update-cache git build-base cmake samurai nlohmann-json && rm -rf /var/cache/apk/*

COPY . /app

RUN cmake -S /app -B /app/build -G Ninja -DCMAKE_BUILD_TYPE:STRING=Release
RUN cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/memory-wrapper.sh", "/app/build/valijson_benchmark"]
CMD []
