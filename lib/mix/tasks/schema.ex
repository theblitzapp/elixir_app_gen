defmodule Mix.Tasks.AppGen.Schema do
  @shortdoc "Creates a ecto schema that has a factory"
  @moduledoc """
  You can use this to create ecto schemas that come with a factory

  ***Note: You must have [`factory_ex`](https://github.com/theblitzapp/factory_ex) installed to use this***

  You can pass in the same arguments you would to `mix phx.gen.schema`

  #### Example

  ```bash
  > mix app_gen.resource --repo MyApp.Repo Accounts.User email:string name:string birthday:date
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
      with :ok <- Mix.Tasks.Phx.Gen.Schema.run(extra_args) do
        System.shell("elixir --erl \"-elixir ansi_enabled true\" -S mix factory_ex.gen --repo #{opts[:repo]} #{ecto_schema_module(extra_args)}", into: IO.stream())
      end
    else
      Mix.raise("Must provide a repo using the --repo flag")
    end
  end

  defp ecto_schema_module(extra_args) do
    "#{AppGenHelpers.app_name()}.#{hd(extra_args)}"
  end
end

