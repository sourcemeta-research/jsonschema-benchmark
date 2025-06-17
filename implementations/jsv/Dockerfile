FROM elixir:1.18.1-otp-27

RUN apt-get update -qq \
    && apt-get install -qq --no-install-recommends \
      time \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

COPY . /app
WORKDIR /app
RUN mix deps.get && mix deps.compile
RUN mix compile
ENTRYPOINT ["/app/memory-wrapper.sh", "mix", "run", "benchmark.exs"]
CMD []
