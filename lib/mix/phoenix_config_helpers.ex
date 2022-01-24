defmodule Mix.PhoenixConfigHelpers do
  def default_config_directory, do: "./lib/phoenix_config/"

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def ensure_init_run!(directory \\ default_config_directory())

  def ensure_init_run!(nil) do
    ensure_init_run!(default_config_directory())
  end

  def ensure_init_run!(directory) do
    if not File.dir?(directory) do
      Mix.raise("Must run mix phoenix_config.init before running this command")
    end
  end

  def write_phoenix_config_file(dirname, file_path, contents) do
    directory = dirname || default_config_directory()
    full_path = Path.join(directory, "#{file_path}.exs")

    Mix.Generator.create_file(full_path, contents)
  end
end
