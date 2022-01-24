defmodule PhoenixConfig.EctoContextGenerator do
  def create_context_module_for_schemas(context_app, context_module, schemas) do
    context_app_string = to_module_string(context_app)
    context_module_string = to_module_string(context_module)
    full_context_module = "#{context_app_string}.#{context_module_string}"

    """
    defmodule #{full_context_module} do
      alias EctoShorts.Actions

      #{schemas |> Enum.map(&"alias #{inspect(&1)}") |> Enum.join("\n")}

      #{schemas |> Enum.map(&create_ecto_shorts_crud_functions/1) |> Enum.join("\n")}
    end
    """
  end

  defp create_ecto_shorts_crud_functions(schema) do
    schema_module = schema |> inspect |> Macro.camelize |> String.split(".") |> List.last

    """
    def create(params) do
        Actions.create(#{schema_module}, params)
      end

      def find(params) do
        Actions.find(#{schema_module}, params)
      end

      def all(params #{"\\"}#{"\\"} %{}) do
        Actions.all(#{schema_module}, params)
      end

      def update(id_or_schema, params) do
        Actions.update(#{schema_module}, id_or_schema, params)
      end

      def delete(id_or_schema) do
        Actions.delete(#{schema_module}, id_or_schema)
      end
    """
  end

  defp to_module_string(any) do
    any |> to_string |> Macro.camelize
  end
end
