defmodule Mix.Tasks.PhoenixConfig.Init do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers

  @shortdoc "Creates the folder for our configs"
  @moduledoc """
  This will create a folder in `./lib/` for `phoenix_config/`, once setup all future
  configs will generate into this folder
  """

  def run(args) do
    PhoenixConfigHelpers.ensure_not_in_umbrella!("phoenix_config.init")

    {opts, _, _} = OptionParser.parse(args, switches: [dirname: :string])

    config_directory = opts[:dirname] || PhoenixConfigHelpers.default_config_directory()

    if not File.dir?(config_directory) do
      Mix.Generator.create_directory(config_directory)
    else
      Mix.raise("Config directory already setup, you may start using phoenix_config.gen comands")
    end
  end
end
