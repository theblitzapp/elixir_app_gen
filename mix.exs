defmodule PhoenixConfig.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_config,
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
      {:absinthe_generator, github: "MikaAK/absinthe_generator"},

      {:phoenix, "~> 1.6"},
      {:jason, "~> 1.3"},
      {:ecto, "~> 3.7", optional: true, runtime: false, only: [:dev, :test]},
      {:ecto_shorts, "~> 1.1", optional: true, runtime: false, only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Mika Kalathil", "theblitzapp"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/theblitzapp/phoenix_config"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib priv)
    ]
  end

  defp docs do
    [
      main: "AbsintheGenerator",
      source_url: "https://github.com/MikaAK/absinthe_generator",

      groups_for_modules: [
        "Mutations": [
          AbsintheGenerator.Mutation
        ],

        "Queries": [
          AbsintheGenerator.Query
        ],

        "Resolvers": [
          AbsintheGenerator.Resolver
        ],

        "Schemas": [
          AbsintheGenerator.Schema,
          AbsintheGenerator.Schema.Field,
          AbsintheGenerator.Schema.Field.Argument,
          AbsintheGenerator.Schema.DataSource,
          AbsintheGenerator.Schema.Middleware
        ],

        "Types": [
          AbsintheGenerator.Type,
          AbsintheGenerator.Type.EnumValue,
          AbsintheGenerator.Type.Object,
          AbsintheGenerator.Type.Object.Field
        ]
      ]
    ]
  end
end
