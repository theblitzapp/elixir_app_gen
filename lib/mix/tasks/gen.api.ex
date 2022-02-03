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
      switches: [dirname: :string, file_name: :string]
    )

    opts[:dirname]
      |> PhoenixConfigHelpers.get_phoenix_config_file_path(opts[:file_path])
      |> eval_config_file
      |> add_schema_generation_struct
      |> Enum.map(&{&1, AbsintheGenerator.run(&1)})
      |> AbsintheTypeMerge.maybe_merge_types
      |> write_generated_templates
  end

  defp add_schema_generation_struct(generation_structs) do
    # app_name = Mix.Project.config()[:app] |> to_string |> Macro.camelize

    # schema_struct = AbsintheGenerator.SchemaBuilder.generate(app_name, generation_structs)

    generation_structs ++ []
  end

  defp eval_config_file(file_path) do
    case Code.eval_file(file_path) do
      {resources, _} -> List.flatten(resources)
    end
  end

  defp write_generated_templates(generation_items) do
    Enum.map(generation_items, fn
      {_generation_struct, [multi_templates | _] = struct_template_tuples} when is_tuple(multi_templates) ->
        Enum.map(struct_template_tuples, fn {generation_struct_item, template} ->
          AbsintheGenerator.FileWriter.write(generation_struct_item, template)
        end)

      {generation_struct, template} ->
        AbsintheGenerator.FileWriter.write(generation_struct, template)
    end)
  end
end
