defmodule LoggerBackends.SQL.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_backends_sql,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:logger_backends, "~> 1.0.0"}
    ]
  end
end
