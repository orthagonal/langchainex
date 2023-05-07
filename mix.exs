defmodule LangchainEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :langchainex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      # prevents protocol consolidation warning
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_openai, "~> 1.1.0"},
      {:jason, "~> 1.2"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "homepage" => "https://github.com/orthagonal/langchainex",
        "repository" => "https://github.com/orthagonal/langchainex.git",
        "docs" => "https://hexdocs.pm/langchainex"
      },
      description: "Language Chains for Elixir"
    ]
  end
end
