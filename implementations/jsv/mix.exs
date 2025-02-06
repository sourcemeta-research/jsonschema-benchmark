defmodule JsonSchemaBenchmark.MixProject do
  use Mix.Project

  def project() do
    [
      app: :json_schema_benchmark,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps()
    ]
  end

  def application() do
    [
    ]
  end

  defp deps() do
    [
      {:jsv, "~> 0.2.0"},
      {:poison, "~> 6.0"}
    ]
  end
end
