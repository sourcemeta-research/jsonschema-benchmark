FROM alpine

RUN apk add --no-cache git build-base cmake

COPY . /app
RUN git clone https://github.com/sourcemeta/blaze /app/repo
RUN git -C /app/repo checkout fat-lto
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/build/blaze_benchmark"]
CMD []
