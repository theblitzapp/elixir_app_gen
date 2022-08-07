defmodule Mix.Tasks.AppGen.Resource do
  use Mix.Task

  alias Mix.AppGenHelpers

  @shortdoc "Used to create app_gen.exs files or to add new CRUD resources in"
  @moduledoc """
  Used to create app_gen.exs
  You can also use this to create contexts and add crud_for_schema into app_gen.exs

  This assumes contexts are the level up from the module, for
  example `MyApp.MyModule.Context.Schema` or `MyApp.Context.Schema`

  #### Example

  ```bash
  > mix app_gen.resource --repo MyApp.Repo MyApp.SomeContext.{Schema,SecondSchema}
  > mix app_gen.resource --repo MyApp.Repo --only create,read,update MyApp.SomeContext.{Schema,SecondSchema}
  > mix app_gen.resource --repo MyApp.Repo --only create --only MyApp.SomeContext.{Schema,SecondSchema}
  ```

  ### Options
  - `dirname` - The directory to generate the config files in
  - `repo` - The repo to use for this generations
  - `file_name` - The file name for the config
  - `only` - Parts to generate (create, all, find, update, delete)
  - `except` - Parts of the CRUD resource to exclude
  """

  def run(args) do
    AppGenHelpers.ensure_not_in_umbrella!("app_gen.resource")

    {opts, ecto_schema_strings, _} = OptionParser.parse(args,
      switches: [
        dirname: :string,
        file_name: :string,
        only: :keep,
        repo: :string,
        except: :keep
      ]
    )

    opts = AppGenHelpers.gather_keep_opts(opts)

    cond do
      Enum.empty?(ecto_schema_strings) ->
        Mix.raise("Must provide schemas for mix app_gen.resource")

      !opts[:repo] ->
        Mix.raise(["Must provide a repo using the", :bright, " --repo ", :reset, :red, "flag"])

      true ->
        ensure_context_modules_created(Mix.Phoenix.context_app(), ecto_schema_strings, opts)

        opts
          |> Keyword.merge(ecto_schemas: ecto_schema_strings)
          |> create_and_write_resource_from_schema
    end
  end

  defp create_and_write_resource_from_schema(opts) do
    ecto_schemas = Enum.map(opts[:ecto_schemas], &AppGenHelpers.string_to_module/1)
    config_file_path = AppGenHelpers.config_file_full_path(opts[:dirname], opts[:file_name])

    if File.exists?(config_file_path) do
      contents = create_config_contents(ecto_schemas, opts[:repo], opts[:only], opts[:except])

      Mix.shell().info("Make sure to merge the following into app_gen.exs\n#{contents}")
    else
      contents = create_config_contents(ecto_schemas, opts[:repo], opts[:only], opts[:except])

      AppGenHelpers.write_app_gen_file(opts[:dirname], opts[:file_name], contents)
    end
  end

  defp create_config_contents(ecto_schemas, repo, only, except) do
    schema_strings = Enum.map(ecto_schemas, &inspect/1)

    """
    import AppGen, only: [crud_from_schema: 2]

    [
      #{crud_schema_strings(schema_strings, only, except)},

      repo_schemas(#{repo}, [
        #{Enum.join(schema_strings, ",\n")}
      ])
    ]
    """
  end

  defp crud_schema_strings(ecto_schemas, only, except) do
    ecto_schemas
      |> Enum.map(&"crud_from_schema(#{&1}#{build_only(only) <> build_except(except)})")
      |> Enum.join(",\n")
  end

  defp build_only(nil), do: ""
  defp build_only(only), do: ", only: #{inspect(list_of_string_to_atoms(only))}"

  defp build_except(nil), do: ""
  defp build_except(except), do: ", except: #{inspect(list_of_string_to_atoms(except))}"

  defp ensure_context_modules_created(context_app, ecto_schema_strings, opts) do
    context_app_module = context_app |> to_string |> Macro.camelize

    ecto_schema_strings
      |> Enum.group_by(&context_module_from_schema_module/1)
      |> Enum.map(fn {context, schemas} ->
        if String.starts_with?(context, "#{context_app_module}.") do
          {context, schemas}
        else
          {"#{context_app_module}.#{context}", schemas}
        end
      end)
      |> Enum.each(&ensure_context_module_create(context_app_module, &1, opts))
  end

  defp ensure_context_module_create(context_app_module, {context, ecto_schemas}, opts) do
    Module.safe_concat([context])

    rescue
      ArgumentError ->
        Mix.shell().info("No context #{context}, creating...")

        ecto_schemas
          |> maybe_strip_app_module(context_app_module)
          |> Mix.Tasks.AppGen.Context.generate_files_from_schemas(opts)

        AppGenHelpers.string_to_module(context_app_module, context)
  end

  defp maybe_strip_app_module(ecto_schemas, context_app_module) do
    Enum.map(ecto_schemas, fn schema ->
      if String.starts_with?(schema, "#{context_app_module}.") do
        String.replace_leading(schema, "#{context_app_module}.", "")
      else
        schema
      end
    end)
  end

  defp context_module_from_schema_module(schema_module) do
    case schema_module |> to_string |> String.split(".") do
      [item] -> item
      schema_parts -> schema_parts |> Enum.drop(-1) |> Enum.join(".")
    end
  end

  defp list_of_string_to_atoms(string) when is_binary(string) do
    list_of_string_to_atoms([string])
  end

  defp list_of_string_to_atoms(strings) do
    Enum.flat_map(strings, fn string ->
      if string =~ "," do
        string |> String.split(",") |> Enum.map(&String.to_atom/1)
      else
        [String.to_atom(string)]
      end
    end)
  end
end

