defmodule Mix.PhoenixConfigHelpers do
  def default_config_directory, do: "./"
  def default_config_file_name, do: "phoenix_config.exs"

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def get_phoenix_config_file_path(dirname, file_name) do
    full_path = config_file_full_path(dirname, file_name)

    if File.exists?(full_path) do
      full_path
    else
      Mix.raise("No config file found at #{full_path}, make sure you run phoenix_config.gen.resource")
    end
  end

  def write_phoenix_config_file(dirname, file_name, contents) do
    Mix.Generator.create_file(config_file_full_path(dirname, file_name), contents)
  end

  def config_file_full_path(dirname, file_name) do
    Path.join(dirname || default_config_directory(), file_name || default_config_file_name())
  end
end
