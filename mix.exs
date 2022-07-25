defmodule AppGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :app_gen,
      version: "0.1.0",
      elixir: "~> 1.12",
      description: "Config as code generation for phoenix applications, don't write apps, generate them",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe_generator, github: "mikaak/absinthe_generator"},

      {:phoenix, "~> 1.5"},
      {:jason, "~> 1.3"},
      {:factory_ex, github: "theblitzapp/factory_ex"},
      {:ecto, "~> 3.0"},
      {:ecto_shorts, ">= 1.0.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Mika Kalathil", "theblitzapp"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/theblitzapp/app_gen"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib priv)
    ]
  end

  defp docs do
    [
      main: "AppGen",
      source_url: "https://github.com/theblitzapp/app_gen",
    ]
  end
end
