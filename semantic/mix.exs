defmodule Semantic.MixProject do
  use Mix.Project

  def project do
    [
      app: :semantic,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:graphvix, "~> 1.1.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
