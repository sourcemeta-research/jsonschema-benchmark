defmodule JsonSchexBenchmark.MixProject do
  use Mix.Project

  def project() do
    [
      app: :jsonschex_benchmark,
      version: "0.0.1",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  def application() do
    []
  end

  defp deps() do
    [
      {:jsonschex, "~> 0.10"},
      {:idna, "~> 7.1"},
      {:decimal, "~> 2.0 or ~> 3.0"}
    ]
  end
end
