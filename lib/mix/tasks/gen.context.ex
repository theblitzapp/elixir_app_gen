defmodule Mix.Tasks.PhoenixConfig.Gen.Context do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers
  alias PhoenixConfig.{EctoContextGenerator, EctoContextTestGenerator}

  def run(args) do
    PhoenixConfigHelpers.ensure_not_in_umbrella!("phoenix_config.gen.context")

    {opts, _extra_args, _} = OptionParser.parse(args,
      switches: [
        tests: :boolean,
        contexts: :boolean,
        force: :boolean,
        quiet: :boolean,
        repo: :string,
        ecto_schema: :keep
      ]
    )

    ecto_schemas = opts
      |> Enum.filter(fn {key, _} -> key === :ecto_schema end)
      |> Enum.map(fn {_, value} -> PhoenixConfigHelpers.string_to_module(value) end)

    repo = PhoenixConfigHelpers.string_to_module(opts[:repo])

    Mix.shell().info(IO.ANSI.format([
      :green, "Creating Ecto contexts in ", :bright, inspect(repo), :reset,
      :green, " for schemas ", :bright, "#{ecto_schemas |> Enum.map(&inspect/1) |> Enum.join(", ")}"
    ], true))

    ecto_schemas
      |> Enum.group_by(&EctoContextGenerator.context_module/1)
      |> Enum.each(fn {context, schemas} ->
        if not opts[:tests] or (opts[:tests] and opts[:contexts]) do
          generate_context_file(context, schemas, opts)
        end

        # if not opts[:tests] or opts[:contexts] and opts[:tests]do
          # generate_test_file(context, schemas, opts)
        # end
      end)
  end

  defp generate_context_file(context, schemas, opts) do
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
  end

  # defp generate_test_file(context, schemas, opts) do
  #   test_contents = EctoContextTestGenerator.create_test_module_for_schemas(
  #     PhoenixConfigHelpers.app_name(),
  #     test,
  #     schemas
  #   )

  #   test_path = EctoContextTestGenerator.test_path(test)

  #   PhoenixConfigHelpers.write_phoenix_config_file(
  #     Path.dirname(test_path),
  #     Path.basename(test_path),
  #     test_contents,
  #     opts
  #   )
  # end
end
