FROM alpine
ARG BLAZE_BRANCH="main"

RUN apk add --no-cache git build-base cmake

COPY . /app
RUN git clone -b ${BLAZE_BRANCH} https://github.com/sourcemeta/blaze /app/repo
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4
ENV LD_PRELOAD=/app/librpmalloc.so
ENTRYPOINT ["/app/build/blaze_benchmark"]
CMD []
