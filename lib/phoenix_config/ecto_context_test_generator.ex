defmodule PhoenixConfig.EctoContextTestGenerator do
  alias PhoenixConfig.EctoContextGenerator

  def create_test_module_for_schemas(context_app, context_module, schemas) do
    context_app_string = to_module_string(context_app)
    context_module_string = to_module_string(context_module)
    full_context_module = "#{context_app_string}.#{context_module_string}"

    Code.format_string!("""
    defmodule #{full_context_module}Test do
      use #{context_app_string}.DataCase, async: true

      #{schemas |> Enum.map(&create_ecto_shorts_crud_tests/1) |> Enum.join("\n")}
    end
    """)
  end

  defp create_ecto_shorts_crud_tests(schema) do
    schema_module = schema |> inspect |> Macro.camelize |> String.split(".") |> List.last
    schema_name = Macro.underscore(schema_module)
    pluralized_schema_name = Inflex.pluralize(to_string(schema_name))

    """
      # #{schema_module} Tests

      describe "&create_#{schema_name}/1" do
        test "creates a module with proper required fields" do

        end
      end

      describe "&find_#{schema_name}/1" do
        test "finds a #{schema_name} by id" do

        end

        test "returns error if #{schema_name} not found" do

        end
      end

      describe "&all_#{pluralized_schema_name}/1" do
        test "returns all #{pluralized_schema_name}" do

        end

        test "filters schema by field" do
        end
      end

      describe "&update_#{schema_name}/2" do
        test "updates a #{schema_name} when passed correct params" do
        end

        test "returns an error when passed invalid params" do

        end
      end

      describe "&delete_#{schema_name}/1" do
        test "removes a #{schema_name} when exists" do

        end
      end

      describe "&find_and_update_or_create_#{schema_name}/1" do
        test "returns a #{schema_name} when exists" do
        end

        test "creates a #{schema_name} when not exists" do
        end

        test "updates a #{schema_name} when exists"
      end
    """
  end

  def to_module_string(any) do
    any |> to_string |> Macro.camelize
  end
end
