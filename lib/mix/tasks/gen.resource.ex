defmodule Mix.Tasks.PhoenixConfig.Gen.Resource do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers

  @shortdoc "Lists help for phoenix_config.gen. commands"
  @moduledoc PhoenixConfig.moduledoc()

  def run(args) do
    {opts, _, _} = OptionParser.parse(args,
      switches: [dirname: :string, name: :string]
    )

    PhoenixConfigHelpers.ensure_init_run!(opts[:dirname])

    if !opts[:name] do
      Mix.raise("Must provide a name to mix phoenix_config.gen.resource using the --name flag")
    end

    if Mix.Generator.overwrite?(opts[:name], "[]") do
      directory = opts[:dirname] || PhoenixConfigHelpers.default_config_directory()

      directory
        |> Path.join("#{opts[:name]}.exs")
        |> Mix.Generator.create_file("[]")
    end
  end
end

