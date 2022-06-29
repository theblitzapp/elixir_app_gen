defmodule PhoenixConfig.EctoContextTestGenerator do
  def test_path(context_module) do
    context_app_module = Mix.Phoenix.context_app()
      |> to_string
      |> Macro.camelize

    context_module = String.replace(context_module, ~r/^#{context_app_module}\./i, "")

    Mix.Phoenix.context_test_path(
      Mix.Phoenix.context_app(),
      "#{Macro.underscore(context_module)}_test.exs"
    )
  end

  def create_test_module_for_schemas(context_app, context_module, schemas) do
    context_app_string = to_module_string(context_app)
    context_module_string = to_module_string(context_module)
    full_context_module = "#{context_app_string}.#{context_module_string}"

    Code.format_string!("""
    defmodule #{full_context_module}Test do
      use #{context_app_string}.DataCase, async: true

      alias #{full_context_module}.Support.Factory

      alias #{full_context_module}

      #{schemas
         |> Enum.map(&create_ecto_shorts_crud_tests(&1, context_module_string))
         |> Enum.join("\n")}
    end
    """)
  end

  defp create_ecto_shorts_crud_tests(schema, context_module_string) do
    schema_module = schema |> inspect |> Macro.camelize |> String.split(".") |> List.last
    schema_name = Macro.underscore(schema_module)
    pluralized_schema_name = Inflex.pluralize(to_string(schema_name))

    """
      # #{schema_module} Tests

      describe "&create_#{schema_name}/1" do
        test "creates a module with proper required fields" do
          params = FactoryEx.build(Factory.#{schema_module})

          assert {:ok, result} = #{context_module_string}.create_#{schema_name}(params)

          assert Map.drop(result, [:__struct__, :__meta__]) === params
        end
      end

      describe "&find_#{schema_name}/1" do
        test "finds a #{schema_name} by id" do
          #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})

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
          #{pluralized_schema_name} = FactoryEx.insert_many!(#{Enum.random(4..15)}, Factory.#{schema_module})

          assert {:ok, results} = #{context_module_string}.all_#{pluralized_schema_name}()

          assert Enum.sort(results, &(&1.id)) === Enum.sort(#{pluralized_schema_name}, &(&1.id))
        end

        test "filters schema by field" do
          #{pluralized_schema_name} = FactoryEx.insert_many!(#{Enum.random(4..15)}, Factory.#{schema_module})
          ids = #{pluralized_schema_name} |> Enum.take(2) |> Enum.map(&(&1.id))

          assert {:ok, results} = #{context_module_string}.all_#{pluralized_schema_name}(%{
            id: ids
          })

          result_ids = Enum.map(results, &(&1.id))

          assert length(result_ids) === length(ids)
          assert Enum.all?(ids, &(&1 in result_ids))
        end
      end

      describe "&update_#{schema_name}/2" do
        test "updates a #{schema_name} when passed correct params" do
          #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})
          update_params = FactoryEx.build_params(Factory.#{schema_module})

          assert {:ok, updated_res} = #{context_module_string}.update_#{schema_name}(
            #{schema_module},
            #{schema_name},
            update_params
          )

          assert update_params === Map.take(updated_res, Map.keys(updated_res))
        end

        test "returns an error when passed invalid params" do
          #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})
          random_key = #{schema_name} |> Map.drop([:__meta__, :__struct__]) |> Map.keys() |> Enum.random
          update_params = FactoryEx.build(Factory.#{schema_module}, %{
            random_key => (if is_binary(schema_name), do: 1234, else: "1234")
          })

          assert {:error, %Ecto.Changeset{valid?: false}} = #{context_module_string}.update_#{schema_name}(
            #{schema_module},
            #{schema_name},
            new_params
          )
        end
      end

      describe "&delete_#{schema_name}/1" do
        test "removes a #{schema_name} when exists" do
          #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})

          assert {:ok, ^#{schema_name}} = #{context_module_string}.delete_#{schema_name}(
            #{schema_module},
            #{schema_name},
            new_params
          )
        end
      end
    """
  end

      # describe "&find_and_upsert#{schema_name}/1" do
      #   test "returns a #{schema_name} when exists" do
      #     #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})
      #     new_params = FactoryEx.build_params(Factory.#{schema_module})

      #     assert {:ok, updated_res} = #{context_module_string}.update_#{schema_name}(
      #       {schema_module},
      #       #{schema_name},
      #       new_params
      #     )

      #     assert new_params === Map.take(updated_res, Map.keys(updated_res))
      #   end

      #   test "creates a #{schema_name} when not exists" do
      #     #{schema_name} = FactoryEx.insert!(Factory.#{schema_module})
      #     new_params = FactoryEx.build_params(Factory.#{schema_module})

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
    any |> to_string |> Macro.camelize
  end
end
