defmodule Mix.Tasks.PhoenixConfig.Gen.Project do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers
  alias PhoenixConfig.{EctoSchemaReflector, EctoContextGenerator}

  @shortdoc "Utilizes all the config files and generates a GraphQL API"
  @moduledoc """
  Once you have a few resource config files created by
  using the `mix phoenix_config.gen.resource` command, you can use
  this command to generate all the api files for Absinthe
  """

  def run(args) do
  end
end
