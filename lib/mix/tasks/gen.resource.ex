defmodule Mix.Tasks.AppGen.Gen.Resource do
  use Mix.Task

  alias Mix.AppGenHelpers
  alias AppGen.EctoContextGenerator

  @shortdoc "Creates a resource file that will be used to configure absinthe routes and can create schemas"
  @moduledoc """
  You can use this to create all resources needed for a GraphQL API

  ### Existing Schema
  If you have an existing schema, you can use the `--from-ecto-schema` flag with the `--context` flag
  to generate a config file for that specific flle

  #### Example

  ```bash
  > mix app_gen.gen.resource --context MyApp.SomeContext --from-ecto-schema MyApp.SomeContext.Schema
  ```

  ### New Schema
  If you're creating a new schema, you can pass in the same arguments you would to `mix phx.gen.schema`

  #### Example

  ```bash
  > mix app_gen.gen.resource Accounts.User email:string name:string birthday:date
  ```

  ### Options
  - `dirname` - The directory to generate the config files in
  - `repo` - The repo to use for this generations
  - `file_name` - The file name for the config
  - `only` - Parts to generate (create, all, find, update, delete)
  - `except` - Parts of the CRUD resource to exclude
  - `context` - Context module if supplying `--from-ecto-schema`
  - `from-ecto-schema` - Specify a specific module instead of generating a new schema
  """

  def run(args) do
    AppGenHelpers.ensure_not_in_umbrella!("app_gen.gen.resource")

    {opts, extra_args, _} = OptionParser.parse(args,
      switches: [
        dirname: :string,
        file_name: :string,
        only: :keep,
        repo: :string,
        except: :keep,
        context: :string,
        from_ecto_schema: :string
      ]
    )

    cond do
      !opts[:from_ecto_schema] and Enum.empty?(extra_args) ->
        Mix.raise("Must provide a from_ecto_schema or create a schema for mix app_gen.gen.resource using the --from-ecto-schema flag")

      !opts[:repo] ->
        Mix.raise("Must provide a repo using the --repo flag")

      opts[:from_ecto_schema] ->
        create_and_write_resource_from_schema(opts)

      extra_args ->
        ecto_schema = create_schema_from_args(extra_args)

        opts
          |> Keyword.merge(from_ecto_schema: ecto_schema)
          |> create_and_write_resource_from_schema
    end
  end

  defp create_and_write_resource_from_schema(opts) do
    from_ecto_schema = safe_concat_with_error([opts[:from_ecto_schema]])
    config_file_path = AppGenHelpers.config_file_full_path(opts[:dirname], opts[:file_name])

    if File.exists?(config_file_path) do
      contents = create_config_contents(from_ecto_schema, opts[:repo], opts[:only], opts[:except])

      # TODO: Inject this instead of forcing user to do this
      Mix.shell.info("Make sure to merge the following with your app_gen.exs\n\n#{contents}")
    else
      contents = create_config_contents(from_ecto_schema, opts[:repo], opts[:only], opts[:except])

      AppGenHelpers.write_app_gen_file(opts[:dirname], opts[:file_name], contents)
    end
  end

  defp create_config_contents(schema_name, repo, nil, nil) do
    """
    import AppGen, only: [crud_from_schema: 1]

    [
      crud_from_schema(#{inspect(schema_name)}),

      repo_schemas(#{inspect(repo)}, [
        #{inspect(schema_name)}
      ])
    ]
    """
  end

  defp create_config_contents(schema_name, repo, only, except) do
    """
    import AppGen, only: [crud_from_schema: 2]

    [
      crud_from_schema(#{inspect(schema_name)}#{build_only(only) <> build_except(except)},

      repo_schemas(#{inspect(repo)}, [
        #{inspect(schema_name)}
      ])
    ]
    """
  end

  defp build_only(nil), do: ""
  defp build_only(only), do: ", only: #{inspect(only)}"

  defp build_except(nil), do: ""
  defp build_except(except), do: ", except: #{inspect(except)}"

  defp create_schema_from_args(extra_args) do
    with :ok <- Mix.Tasks.Phx.Gen.Schema.run(extra_args) do
      context_app = Mix.Phoenix.context_app() |> to_string |> Macro.camelize

      schema_module = hd(extra_args)
      context_module = context_module_from_schema_module(schema_module)
      ecto_schema = safe_concat_with_error(context_app, schema_module)

      ensure_context_module_created(Mix.Phoenix.context_app(), context_module, ecto_schema)

      inspect(ecto_schema)
    end
  end

  defp ensure_context_module_created(context_app, context_module, ecto_schema) do
    context_app_module = context_app |> to_string |> Macro.camelize
    Module.safe_concat(context_app_module, context_module)

    rescue
      ArgumentError ->
        context_app_module = context_app |> to_string |> Macro.camelize

        Mix.shell().info("No context found for schema at #{context_app_module}.#{context_module}, creating...")

        context_module_path = Mix.Phoenix.context_lib_path(context_app, "#{Macro.underscore(context_module)}.ex")

        if Mix.Generator.create_file(context_module_path, EctoContextGenerator.create_context_module_for_schemas(context_app_module, context_module, [ecto_schema])) do
          Code.compile_file(context_module_path)

          safe_concat_with_error(context_app_module, context_module)
        end
  end

  defp safe_concat_with_error(module_a, module_b) do
    safe_concat_with_error([module_a, module_b])
  end

  defp safe_concat_with_error(modules) do
    Module.safe_concat(modules)

    rescue
      ArgumentError ->
        Mix.raise("Module #{Enum.join(modules, ".")} cannot be found in your application, please ensure you have the right modules passed in")
  end

  defp context_module_from_schema_module(schema_module) do
    case schema_module |> to_string |> String.split(".") do
      [item] -> item
      schema_parts -> schema_parts |> Enum.drop(-1) |> Enum.join(".")
    end
  end
end

