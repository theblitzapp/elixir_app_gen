defmodule Mix.Tasks.AppGen.Schema do
  @shortdoc "Creates a ecto schema that has a factory"
  @moduledoc """
  You can use this to create ecto schemas that come with a factory

  ***Note: You must have [`factory_ex`](https://github.com/theblitzapp/factory_ex) installed to use this***

  You can pass in the same arguments you would to `mix phx.gen.schema`

  #### Example

  ```bash
  > mix app_gen.schema --repo MyApp.Repo Accounts.User account_users email:string name:string birthday:date
  ```

  ### Options
  - `dirname` - The directory to generate the config files in
  - `repo` - The repo to use for this generations
  - `file_name` - The file name for the config
  """

  use Mix.Task

  alias Mix.AppGenHelpers

  def run(args) do
    AppGenHelpers.ensure_not_in_umbrella!("app_gen.gen.resource")

    {opts, extra_args, _} = OptionParser.parse(args,
      switches: [
        dirname: :string,
        file_name: :string,
        repo: :string
      ]
    )


    if opts[:repo] do
      validate_repo!(opts[:repo])

      with :ok <- Mix.Tasks.Phx.Gen.Schema.run(extra_args) do
        require_new_schema_file(extra_args)
        generate_factory(extra_args, opts)
      end
    else
      Mix.raise("Must provide a repo using the --repo flag")
    end
  end

  defp generate_factory(extra_args, opts) do
    extra_args
      |> ecto_schema_module
      |> AppGenHelpers.string_to_module
      |> Mix.Tasks.FactoryEx.Gen.generate_factory(opts[:repo], opts)
  end

  defp validate_repo!(repo) do
    AppGenHelpers.string_to_module(repo)
  end

  defp require_new_schema_file(extra_args) do
    module = hd(extra_args)
    context_app = to_string(Mix.Phoenix.context_app())
    schema_path = Path.join(["..", context_app, "lib", context_app | module |> String.split(".") |> Enum.map(&Macro.underscore/1)])

    Code.require_file("#{schema_path}.ex")
  end

  defp ecto_schema_module(extra_args) do
    context_module = Mix.Phoenix.context_app()
      |> to_string
      |> Macro.camelize

    "#{context_module}.#{hd(extra_args)}"
  end
end

