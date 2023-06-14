defmodule Mix.AppGenHelpers do
  @spec app_name :: String.t()
  def app_name do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()
  end

  @spec default_config_directory :: String.t()
  def default_config_directory, do: "./"

  @spec default_config_file_name :: String.t()
  def default_config_file_name, do: "app_gen.exs"

  @spec ensure_not_in_umbrella!(String.t()) :: :ok
  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix #{command} must be invoked from within your *_web application root directory"
      )
    end

    :ok
  end

  @spec get_app_gen_file_path(String.t(), String.t()) :: String.t()
  def get_app_gen_file_path(dirname, file_name) do
    full_path = config_file_full_path(dirname, file_name)

    if File.exists?(full_path) do
      full_path
    else
      Mix.raise("No config file found at #{full_path}, make sure you run app_gen.gen.resource")
    end
  end

  @spec write_app_gen_file(String.t(), String.t(), iodata) :: boolean
  @spec write_app_gen_file(String.t(), String.t(), iodata, keyword) :: boolean
  def write_app_gen_file(dirname, file_name, contents, opts \\ []) do
    dirname
    |> config_file_full_path(file_name)
    |> Path.relative_to_cwd()
    |> Mix.Generator.create_file(
      contents,
      opts
    )
  end

  @spec config_file_full_path(String.t(), String.t()) :: String.t()
  def config_file_full_path(dirname, file_name) do
    Path.join(dirname || default_config_directory(), file_name || default_config_file_name())
  end

  @spec string_to_module(String.t()) :: module
  @spec string_to_module(String.t(), String.t()) :: module
  @spec string_to_module([String.t()]) :: module
  def string_to_module(module_a, module_b) do
    string_to_module([module_a, module_b])
  end

  def string_to_module(module) when is_binary(module) do
    string_to_module([module])
  end

  def string_to_module(modules) do
    Module.safe_concat(modules)
  rescue
    ArgumentError ->
      Mix.raise("Module #{Enum.join(modules, ".")} cannot be found in your application")
  end

  @spec gather_keep_opts(keyword) :: keyword
  def gather_keep_opts(opts) do
    Enum.reduce(opts, [], fn {key, value}, acc ->
      Keyword.update(acc, key, value, fn
        list when is_list(list) -> list ++ [value]
        item -> [item, value]
      end)
    end)
  end
end
