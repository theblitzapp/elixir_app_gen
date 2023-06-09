defmodule Mix.Tasks.AppGen.Context do
  @shortdoc "Creates a ecto context with functions from EctoShorts as well as tests"
  @moduledoc """
  You can use this to create ecto schema contexts and related tests

  ***Note: You must have [`ecto`](https://github.com/mikaak/ecto) installed to use this***

  #### Example
  `--repo` is a required flag for the ecto repo

  ```bash
  > mix app_gen.context --repo MyApp.Repo MyContext.MySchema
  ```
  """

  use Mix.Task

  alias Mix.AppGenHelpers
  alias AppGen.{EctoContextGenerator, EctoContextTestGenerator}

  def run(args) do
    AppGenHelpers.ensure_not_in_umbrella!("app_gen.gen.context")

    {opts, extra_args, _} =
      OptionParser.parse(args,
        switches: [
          no_tests: :boolean,
          no_contexts: :boolean,
          force: :boolean,
          quiet: :boolean,
          repo: :string
        ]
      )

    ecto_schemas = Enum.map(extra_args, &AppGenHelpers.string_to_module/1)

    if Enum.empty?(ecto_schemas) do
      raise to_string(
              IO.ANSI.format([
                :red,
                "No schemas provided to ",
                :bright,
                "app_gen.context",
                :reset,
                :red,
                ", you must provide at least one",
                :reset
              ])
            )
    end

    repo_str =
      if opts[:repo] do
        opts[:repo] |> AppGenHelpers.string_to_module() |> inspect
      else
        "the default repo"
      end

    Mix.shell().info(
      IO.ANSI.format(
        [
          :green,
          "Creating Ecto contexts in ",
          :bright,
          repo_str,
          :reset,
          :green,
          " for schemas ",
          :bright,
          "#{ecto_schemas |> Enum.map(&inspect/1) |> Enum.join(", ")}"
        ],
        true
      )
    )

    generate_files_from_schemas(ecto_schemas, opts)
  end

  def generate_files_from_schemas(ecto_schemas, opts) do
    ecto_schemas
    |> Enum.group_by(&EctoContextGenerator.context_module/1)
    |> Enum.each(fn {context, schemas} ->
      unless opts[:no_contexts] do
        generate_context_file(context, schemas, opts)
      end

      unless opts[:no_tests] do
        generate_test_file(context, schemas, opts)
      end
    end)
  end

  defp generate_context_file(context, schemas, opts) do
    context_contents =
      EctoContextGenerator.create_context_module_for_schemas(
        opts[:repo],
        context,
        schemas
      )

    context_path = EctoContextGenerator.context_path(context)

    AppGenHelpers.write_app_gen_file(
      Path.dirname(context_path),
      Path.basename(context_path),
      context_contents,
      opts
    )
  end

  defp generate_test_file(context, schemas, opts) do
    test_contents =
      EctoContextTestGenerator.create_test_module_for_schemas(
        context,
        schemas
      )

    test_path = EctoContextTestGenerator.test_path(context)

    AppGenHelpers.write_app_gen_file(
      Path.dirname(test_path),
      Path.basename(test_path),
      test_contents,
      opts
    )
  end
end
