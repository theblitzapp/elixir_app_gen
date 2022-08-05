defmodule Mix.AppGenHelpers do
  def app_name, do: Mix.Project.config()[:app] |> to_string |> Macro.camelize

  def default_config_directory, do: "./"
  def default_config_file_name, do: "app_gen.exs"

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def get_app_gen_file_path(dirname, file_name) do
    full_path = config_file_full_path(dirname, file_name)

    if File.exists?(full_path) do
      full_path
    else
      Mix.raise("No config file found at #{full_path}, make sure you run app_gen.gen.resource")
    end
  end

  def write_app_gen_file(dirname, file_name, contents, opts \\ []) do
    dirname
      |> config_file_full_path(file_name)
      |> Path.relative_to_cwd
      |> Mix.Generator.create_file(
        contents,
        opts
      )
  end

  def config_file_full_path(dirname, file_name) do
    Path.join(dirname || default_config_directory(), file_name || default_config_file_name())
  end

  def string_to_module(module_string) do
    Module.safe_concat([module_string])

    rescue
      ArgumentError ->
        raise to_string(IO.ANSI.format([
          :red,
          "Module ",
          :bright,
          module_string,
          :reset,
          :red,
          " doesn't exist",
          :reset
        ]))
  end
end
