defmodule Mix.Tasks.PhoenixConfig.Gen.Api do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers
  alias PhoenixConfig.AbsintheTypeMerge

  @shortdoc "Utilizes all the config files and generates a GraphQL API"
  @moduledoc """
  Once you have a few resource config files created by
  using the `mix phoenix_config.gen.resource` command, you can use
  this command to generate all the api files for Absinthe
  """

  def run(args) do
    PhoenixConfigHelpers.ensure_not_in_umbrella!("phoenix_config.gen.project")

    {opts, _extra_args, _} = OptionParser.parse(args,
      switches: [dirname: :string]
    )

    PhoenixConfigHelpers.ensure_init_run!(opts[:dirname])

    config_files = PhoenixConfigHelpers.get_phoenix_config_files(opts[:dirname])

    if config_files === [] do
      Mix.raise("No config files found, please make sure you've generated some using `mix phoenix_config.gen.resource`")
    end

    config_files
      |> Enum.flat_map(&eval_config_file/1)
      |> AbsintheTypeMerge.maybe_merge_types
      |> Enum.map(&{&1, AbsintheGenerator.run(&1)})
      |> Enum.map(fn
        {_generation_struct, struct_template_tuples} when is_list(struct_template_tuples) ->
          Enum.map(struct_template_tuples, fn {generation_struct_item, template} ->
            AbsintheGenerator.FileWriter.write(generation_struct_item, template)
          end)

        {generation_struct, template} ->
          AbsintheGenerator.FileWriter.write(generation_struct, template)
      end)
  end

  defp eval_config_file(file_path) do
    case Code.eval_file(file_path) do
      {resources, _} -> resources
    end
  end
end
