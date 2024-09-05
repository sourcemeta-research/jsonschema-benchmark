FROM alpine

RUN apk add --no-cache git clang llvm make cmake

COPY . /app
RUN git clone https://github.com/sourcemeta/jsontoolkit /app/repo
ENV CC=clang CXX=clang++
RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/build/jsontoolkit_benchmark"]
CMD []
