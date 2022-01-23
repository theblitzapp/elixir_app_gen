defmodule PhoenixConfig.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_config,
      version: "0.1.0",
      elixir: "~> 1.12",
      description: "Config as code generation for phoenix applications, don't write apps, generate them",
      start_permanent: Mix.env() == :prod,
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
      {:absinthe_generator, github: "MikaAK/absinthe_generator"}
    ]
  end

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
