defmodule Mix.Tasks.AppGen.Gen.Api do
  use Mix.Task

  alias Mix.AppGenHelpers
  alias AppGen.{AbsintheTypeMerge, AbsintheSchemaBuilder}

  @shortdoc "Utilizes all the config files and generates a GraphQL API"
  @moduledoc """
  Once you have a few resource config files created by
  using the `mix app_gen.gen.resource` command, you can use
  this command to generate all the api files for Absinthe
  """

  def run(args) do
    AppGenHelpers.ensure_not_in_umbrella!("app_gen.gen.api")

    {opts, _extra_args, _} = OptionParser.parse(args,
      switches: [
        dirname: :string,
        file_name: :string,
        force: :boolean,
        quiet: :boolean
      ]
    )

    opts[:dirname]
      |> AppGenHelpers.get_app_gen_file_path(opts[:file_name])
      |> eval_config_file
      |> expand_crud_types
      |> pre_merge_types
      |> AbsintheSchemaBuilder.generate
      |> run_config_functions
      |> AbsintheTypeMerge.maybe_merge_types
      |> generate_templates
      |> write_generated_templates(Keyword.take(opts, [:force, :quiet]))
  end

  defp pre_merge_types(generation_items) do
    {functions, generation_structs} = Enum.split_with(generation_items, &is_function/1)

    AbsintheTypeMerge.maybe_merge_types(generation_structs) ++ functions
  end

  defp expand_crud_types(generation_items) do
    Enum.flat_map(generation_items, fn
      %AbsintheGenerator.CrudResource{} = generation_item ->
        generation_item |> AbsintheGenerator.CrudResource.run |> Enum.map(&elem(&1, 0))

      generation_item -> [generation_item]
    end)
  end

  defp eval_config_file(file_path) do
    {resources, _} = Code.eval_file(file_path)

    List.flatten(resources)
  end

  defp run_config_functions(generation_items) do
    {config_functions, generation_structs} = Enum.split_with(generation_items, &is_function/1)

    Enum.reduce(config_functions, generation_structs, fn func, items_acc ->
      func.(items_acc)
    end)
  end

  defp generate_templates(generation_structs) do
    generation_structs
      |> Enum.reduce([], fn
        (generation_item, acc) ->
          case AbsintheGenerator.run(generation_item) do
            [str | _] = template when is_binary(str) ->
              [{generation_item, template} | acc]

            generation_item_children -> generation_item_children ++ acc
          end
      end)
      |> Enum.reverse
  end

  defp write_generated_templates(generation_items, opts) do
    Enum.map(generation_items, fn
      {_generation_struct, [multi_templates | _] = struct_template_tuples} when is_tuple(multi_templates) ->
        Enum.map(struct_template_tuples, fn {generation_struct_item, template} ->
          AbsintheGenerator.FileWriter.write(generation_struct_item, template, opts)
        end)

      {generation_struct, template} ->
        AbsintheGenerator.FileWriter.write(generation_struct, template, opts)
    end)
  end
end
