defmodule PhoenixConfig.AbsintheTypeMerge do
  alias PhoenixConfig.EctoSchemaReflector

  def maybe_merge_types(absinthe_generator_schemas) do
    absinthe_generator_schemas
  end

  def remove_relations(absinthe_generator_schemas, ecto_schema, relation_key) when is_atom(relation_key) do
    remove_relations(absinthe_generator_schemas, ecto_schema, [relation_key])
  end

  def remove_relations(absinthe_generator_schemas, ecto_schema, relation_key) when is_binary(relation_key) do
    remove_relations(absinthe_generator_schemas, ecto_schema, [relation_key])
  end

  def remove_relations(absinthe_generator_schemas, ecto_schema, relation_keys) do
    Enum.map(absinthe_generator_schemas, fn
      {%AbsintheGenerator.Type{} = type, _} ->
        type = %{type |
          objects: Enum.map(type.objects, fn object ->
            %{object | fields: Enum.reject(object.fields, fn field ->
              (not is_nil(field.resolver) and
                object.name =~ EctoSchemaReflector.ecto_module_resource_name(ecto_schema) and
                field.name in Enum.map(relation_keys, &to_string/1)) |> IO.inspect
            end)}
          end)
        }

        {type, AbsintheGenerator.run(type)}

      schema -> schema
    end)
  end
end
