FROM elixir:1.18.1-otp-27

ENV MIX_ENV=prod

COPY . /app
WORKDIR /app
RUN mix deps.get && mix deps.compile
RUN mix compile
ENTRYPOINT ["mix", "run", "benchmark.exs"]
CMD []
