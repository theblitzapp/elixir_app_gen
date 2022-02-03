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
      |> ensure_functions_last_in_list
      |> reduce_config_to_structs
      |> AbsintheTypeMerge.maybe_merge_types
      |> add_schema_generation_struct
      |> write_generated_templates
  end

  defp eval_config_file(file_path) do
    case Code.eval_file(file_path) do
      {resources, _} -> List.flatten(resources)
    end
  end

  defp add_schema_generation_struct(generation_item_tuples) do
    schema_struct = AbsintheGenerator.SchemaBuilder.generate(
      PhoenixConfigHelpers.app_name(),
      Enum.map(generation_item_tuples, fn {generation_struct, _template} -> generation_struct end)
    )

    generation_item_tuples ++ [{schema_struct, AbsintheGenerator.run(schema_struct)}]
  end

  defp ensure_functions_last_in_list(generation_items) do
    {functions, generation_items} = Enum.split_with(generation_items, &is_function/1)

    generation_items ++ functions
  end

  def reduce_config_to_structs(generation_items) do
    generation_items
      |> Enum.reduce([], fn
        (config_function, acc) when is_function(config_function) -> config_function.(acc)
        (generation_item, acc) ->
          case AbsintheGenerator.run(generation_item) do
            [str | _] = template when is_binary(str) ->
              [{generation_item, template} | acc]

            generation_item_children -> generation_item_children ++ acc
          end
      end)
      |> Enum.reverse
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
