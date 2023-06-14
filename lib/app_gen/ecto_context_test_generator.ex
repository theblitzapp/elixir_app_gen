defmodule AppGen.EctoContextTestGenerator do
  def test_path(context_module) do
    context_app_module =
      Mix.Phoenix.context_app()
      |> to_string
      |> Macro.camelize()

    context_module = String.replace(context_module, ~r/^#{context_app_module}\./i, "")

    Mix.Phoenix.context_test_path(
      Mix.Phoenix.context_app(),
      "#{Macro.underscore(context_module)}_test.exs"
    )
  end

  def create_test_module_for_schemas(context_module, schemas) do
    context_module_full = to_module_string(context_module)
    [app_string | context_module] = String.split(context_module_full, ".")

    Code.format_string!("""
    defmodule #{context_module_full}Test do
      use #{app_string}.DataCase, async: true

      alias #{app_string}.Support.Factory

      alias #{context_module_full}

      #{Enum.map_join(schemas, "\n", &create_ecto_shorts_crud_tests(&1, context_module))}
    end
    """)
  end

  defp create_ecto_shorts_crud_tests(schema, context_module_string) do
    schema_module = schema |> inspect |> Macro.camelize() |> String.split(".") |> List.last()
    schema_name = Macro.underscore(schema_module)
    pluralized_schema_name = Inflex.pluralize(to_string(schema_name))
    factory_name = "Factory.#{context_module_string}.#{schema_module}"

    """
      # #{schema_module} Tests

      describe "&create_#{schema_name}/1" do
        test "creates a module with proper required fields" do
          params = FactoryEx.build_params(#{factory_name})

          assert {:ok, result} = #{context_module_string}.create_#{schema_name}(params)

          refute is_nil(result.id)
          assert Map.take(result, Map.keys(params)) === params
        end
      end

      describe "&find_#{schema_name}/1" do
        test "finds a #{schema_name} by id" do
          #{schema_name} = FactoryEx.insert!(#{factory_name})

          assert {:ok, ^#{schema_name}} = #{context_module_string}.find_#{schema_name}(%{
            id: #{schema_name}.id
          })
        end

        test "returns error if #{schema_name} not found" do
          assert {:error, %ErrorMessage{code: :not_found}} = #{context_module_string}.find_#{schema_name}(%{
            id: Enum.random(1..100_000)
          })
        end
      end

      describe "&all_#{pluralized_schema_name}/1" do
        test "returns all #{pluralized_schema_name}" do
          #{pluralized_schema_name} = FactoryEx.insert_many!(#{Enum.random(4..15)}, #{factory_name})

          results = #{context_module_string}.all_#{pluralized_schema_name}()

          assert Enum.sort_by(results, &(&1.id)) === Enum.sort_by(#{pluralized_schema_name}, &(&1.id))
        end

        test "filters schema by field" do
          #{pluralized_schema_name} = FactoryEx.insert_many!(#{Enum.random(4..15)}, #{factory_name})
          ids = #{pluralized_schema_name} |> Enum.take(2) |> Enum.map(&(&1.id))

          results = #{context_module_string}.all_#{pluralized_schema_name}(%{
            id: ids
          })

          result_ids = Enum.map(results, &(&1.id))

          assert length(result_ids) === length(ids)
          assert Enum.all?(ids, &(&1 in result_ids))
        end
      end

      describe "&update_#{schema_name}/2" do
        test "updates a #{schema_name} when passed correct params" do
          #{schema_name} = FactoryEx.insert!(#{factory_name})
          update_params = FactoryEx.build_params(#{factory_name})

          assert {:ok, updated_res} = #{context_module_string}.update_#{schema_name}(
            #{schema_name},
            update_params
          )

          assert update_params === Map.take(updated_res, Map.keys(update_params))
        end

        test "returns an error when passed invalid params" do
          #{schema_name} = FactoryEx.insert!(#{factory_name})
          update_params = FactoryEx.build_invalid_params(#{factory_name})

          assert {:error, %Ecto.Changeset{valid?: false}} = #{context_module_string}.update_#{schema_name}(
            #{schema_name},
            update_params
          )
        end
      end

      describe "&delete_#{schema_name}/1" do
        test "removes a #{schema_name} when exists" do
          #{schema_name} = FactoryEx.insert!(#{factory_name})
          id = #{schema_name}.id

          assert {:ok, %#{context_module_string}.#{schema_module}{
            id: ^id
          }} = #{context_module_string}.delete_#{schema_name}(#{schema_name}.id)
        end
      end
    """
  end

  # describe "&find_and_upsert#{schema_name}/1" do
  #   test "returns a #{schema_name} when exists" do
  #     #{schema_name} = FactoryEx.insert!(#{factory_name})
  #     new_params = FactoryEx.build_params(#{factory_name})

  #     assert {:ok, updated_res} = #{context_module_string}.update_#{schema_name}(
  #       {schema_module},
  #       #{schema_name},
  #       new_params
  #     )

  #     assert new_params === Map.take(updated_res, Map.keys(updated_res))
  #   end

  #   test "creates a #{schema_name} when not exists" do
  #     #{schema_name} = FactoryEx.insert!(Factory.#{context_module})
  #     new_params = FactoryEx.build_params(Factory.#{context_module})

  #     assert {:ok, updated_res} = #{context_module_string}.update_#{schema_name}(
  #       {schema_module},
  #       #{schema_name},
  #       new_params
  #     )

  #     assert new_params === Map.take(updated_res, Map.keys(updated_res))
  #   end

  #   test "updates a #{schema_name} when exists" do
  #   end
  # end

  def to_module_string(any) do
    any |> to_string |> Macro.camelize()
  end
end
