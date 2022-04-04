defmodule Mix.Tasks.PhoenixConfig.Gen.Context do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers
  alias PhoenixConfig.{EctoContextGenerator}

  def run(args) do
    PhoenixConfigHelpers.ensure_not_in_umbrella!("phoenix_config.gen.context")

    {opts, _extra_args, _} = OptionParser.parse(args,
      switches: [
        force: :boolean,
        quiet: :boolean,
        ecto_schema: :keep
      ]
    )

    ecto_schemas = opts
      |> Enum.filter(fn {key, _} -> key === :ecto_schema end)
      |> Enum.map(fn {_, value} -> PhoenixConfigHelpers.string_to_module(value) end)

    Mix.shell().info(
      IO.ANSI.green() <>
      ("Creating Ecto contexts for schemas #{ecto_schemas |> Enum.map(&inspect/1) |> Enum.join(", ")}") <>
      IO.ANSI.reset()
    )

    ecto_schemas
      |> Enum.group_by(&EctoContextGenerator.context_module/1)
      |> Enum.each(fn {context, schemas} ->
        context_contents = EctoContextGenerator.create_context_module_for_schemas(
          PhoenixConfigHelpers.app_name(),
          context,
          schemas
        )

        context_path = EctoContextGenerator.context_path(context)

        PhoenixConfigHelpers.write_phoenix_config_file(
          Path.dirname(context_path),
          Path.basename(context_path),
          context_contents,
          opts
        )
      end)
  end
end
