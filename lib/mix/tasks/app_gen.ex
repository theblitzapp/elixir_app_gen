defmodule Mix.Tasks.AppGen do
  use Mix.Task

  @shortdoc "Lists help for app_gen commands"
  @moduledoc AppGen.moduledoc()

  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.Task.run("help", ["--search", "app_gen.phx.new"])
    else
      Mix.Task.run("help", ["app_gen"])
    end
  end
end
