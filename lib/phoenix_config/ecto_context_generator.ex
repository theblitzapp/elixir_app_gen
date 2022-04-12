defmodule PhoenixConfig.EctoContextGenerator do
  def context_path(context_module) do
    context_app_module = Mix.Phoenix.context_app()
      |> to_string
      |> Macro.camelize

    context_module = String.replace(context_module, ~r/^#{context_app_module}\./i, "")

    Mix.Phoenix.context_lib_path(Mix.Phoenix.context_app(), "#{Macro.underscore(context_module)}.ex")
  end

  def context_module(schema) when is_atom(schema) do
    context_module(inspect(schema))
  end

  def context_module(schema) when is_binary(schema) do
    schema
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
  end

  def create_context_module_for_schemas(context_app, context_module, schemas) do
    context_app_string = to_module_string(context_app)
    context_module_string = to_module_string(context_module)
    full_context_module = "#{context_app_string}.#{context_module_string}"

    Code.format_string!("""
    defmodule #{full_context_module} do
      alias EctoShorts.Actions

      #{schemas |> Enum.map(&"alias #{inspect(&1)}") |> Enum.join("\n")}

      #{schemas |> Enum.map(&create_ecto_shorts_crud_functions/1) |> Enum.join("\n")}
    end
    """)
  end

  defp create_ecto_shorts_crud_functions(schema) do
    schema_module = schema |> inspect |> Macro.camelize |> String.split(".") |> List.last
    schema_name = Macro.underscore(schema_module)

    """
      def create_#{schema_name}(params) do
        Actions.create(#{schema_module}, params)
      end

      def find_#{schema_name}(params) do
        Actions.find(#{schema_module}, params)
      end

      def all_#{Inflex.pluralize(to_string(schema_name))}(params #{"\\"}#{"\\"} %{}) do
        Actions.all(#{schema_module}, params)
      end

      def update_#{schema_name}(id_or_schema, params) do
        Actions.update(#{schema_module}, id_or_schema, params)
      end

      def delete_#{schema_name}(id_or_schema) do
        Actions.delete(#{schema_module}, id_or_schema)
      end

      def find_and_update_or_create_#{schema_name}(params, update_params) do
        Actions.find_and_update(#{schema_module}, params, update_params)
      end
    """
  end

  defp to_module_string(any) do
    any |> to_string |> Macro.camelize
  end
end
