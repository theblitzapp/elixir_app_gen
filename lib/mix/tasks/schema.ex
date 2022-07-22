defmodule Mix.Tasks.AppGen.Schema do
  @shortdoc "Creates a ecto schema that has a factory"
  @moduledoc """
  You can use this to create ecto schemas that come with a factory

  ***Note: You must have [`factory_ex`](https://github.com/theblitzapp/factory_ex) installed to use this***

  You can pass in the same arguments you would to `mix phx.gen.schema`

  #### Example

  ```bash
  > mix app_gen.resource Accounts.User email:string name:string birthday:date
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

  use Mix.Task

  alias Mix.AppGenHelpers

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
end

