defmodule AppGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :app_gen,
      version: "0.1.1",
      elixir: "~> 1.12",
      description:
        "Config as code generation for phoenix applications, don't write apps, generate them",
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        ignore_warnings: ".dialyzer-ignore.exs",
        plt_add_apps: [:ex_unit, :mix, :credo],
        list_unused_filters: true,
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        flags: [:unmatched_returns]
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [
        coveralls: :test,
        doctor: :test,
        coverage: :test,
        "coverage.html": :test,
        "coveralls.json": :test,
        "coveralls.lcov": :test,
        credo: :test,
        dialyzer: :test,
        test: :test
      ],
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: docs(),
      package: package(),
      xref: [exclude: [Mix.Tasks.Phx.New]]
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
      {:absinthe_generator, "~> 0.1"},
      {:factory_ex, "~> 0.2", only: [:dev, :test]},
      {:phoenix, "~> 1.5"},
      {:jason, "~> 1.3"},
      {:ecto, "~> 3.0"},
      {:ecto_shorts, ">= 1.0.0"},
      {:credo, "~> 1.4", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: :test, runtime: false},
      {:excoveralls, "~> 0.13", only: :test, runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21.0", only: :test},
      {:nimble_parsec, "~> 1.1"}
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
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib)
    ]
  end

  defp docs do
    [
      main: "AppGen",
      source_url: "https://github.com/theblitzapp/app_gen"
    ]
  end
end
