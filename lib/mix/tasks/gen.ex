defmodule Mix.Tasks.PhoenixConfig.Gen do
  use Mix.Task

  alias Mix.PhoenixConfigHelpers

  @shortdoc "Lists help for phoenix_config.gen. commands"
  @moduledoc PhoenixConfig.moduledoc()

  def run(_args) do
    PhoenixConfigHelpers.ensure_not_in_umbrella!("phoenix_config.gen")

    Mix.Task.run("help", ["--search", "phoenix_config"])
  end
end
