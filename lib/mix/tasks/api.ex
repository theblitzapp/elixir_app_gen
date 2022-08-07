defmodule Mix.Tasks.AppGen.Api do
  use Mix.Task

  alias Mix.AppGenHelpers
  alias AppGen.ConfigState

  @shortdoc "Utilizes all the config files and generates a GraphQL API"
  @moduledoc """
  Once you have a resource config file created by
  using the `mix app_gen.resource` command, you can use
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
      |> ConfigState.parse_and_expand
      |> generate_templates
      |> write_generated_templates(Keyword.take(opts, [:force, :quiet]))
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
