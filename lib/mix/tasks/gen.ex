defmodule Mix.Tasks.AppConfig.Gen do
  use Mix.Task

  alias Mix.AppConfigHelpers

  @shortdoc "Lists help for app_config.gen. commands"
  @moduledoc AppConfig.moduledoc()

  def run(_args) do
    AppConfigHelpers.ensure_not_in_umbrella!("app_config.gen")

    Mix.Task.run("help", ["--search", "app_config"])
  end
end
