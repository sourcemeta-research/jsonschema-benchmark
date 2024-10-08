FROM alpine

RUN apk add --update-cache git build-base cmake ninja ninja-build curl zip unzip pkgconf && rm -rf /var/cache/apk/*

RUN git clone --branch 2024.04.26 https://github.com/microsoft/vcpkg /app/vcpkg && /app/vcpkg/bootstrap-vcpkg.sh
ENV VCPKG_ROOT=/app/vcpkg
ENV PATH=$VCPKG_ROOT:/usr/lib/ninja-build/bin:$PATH
ENV CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

COPY . /app

RUN cmake -S /app -B /app/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
RUN cmake --build /app/build --config Release --parallel 4
ENTRYPOINT ["/app/build/jsoncons_benchmark"]
CMD []
