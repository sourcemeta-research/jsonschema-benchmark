FROM alpine

RUN apk add --no-cache git build-base cmake

COPY . /app
RUN git clone https://github.com/sourcemeta/blaze /app/repo
RUN git -C /app/repo checkout a031b308789a8c3e739831a95e8e374ea6a3d575
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/build/blaze_benchmark"]
CMD []
