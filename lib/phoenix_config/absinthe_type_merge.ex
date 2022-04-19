defmodule PhoenixConfig.AbsintheTypeMerge do
  alias PhoenixConfig.EctoSchemaReflector

  def maybe_merge_types(absinthe_generator_structs) do
    {non_type_structs, duplicate_type_structs_map} = absinthe_generator_structs
      |> Enum.group_by(&Map.get(&1, :type_name))
      |> Map.pop(nil)

    duplicate_type_structs_map
      |> resolve_duplicate_types
      |> Enum.concat(non_type_structs)
  end

  defp resolve_duplicate_types(duplicate_type_structs_map) do
    Enum.flat_map(duplicate_type_structs_map, fn
      {_dup_key, type_struct_tuple} when length(type_struct_tuple) <= 1 -> type_struct_tuple
      {_dup_key, type_struct_tuples} -> [merge_types(type_struct_tuples)]
    end)
  end

  defp merge_types(type_structs) do
    merged_type_struct = Enum.reduce(
      type_structs,
      fn type_struct, acc_type_struct ->
        %{acc_type_struct |
          enums: merge_enum_objects(acc_type_struct.enums, type_struct.enums),
          objects: merge_type_objects(acc_type_struct.objects, type_struct.objects)
        }
    end)

    merged_type_struct
  end

  defp merge_type_objects(type_objects, duplicate_type_objects) do
    Enum.reduce(duplicate_type_objects, type_objects, fn type_obj, type_objects_acc ->
      if Enum.any?(type_objects_acc, &(&1.name === type_obj.name)) do
        type_objects_acc
      else
        [type_obj | type_objects_acc]
      end
    end)
  end

  defp merge_enum_objects(enums_a, _enums_b) do
    enums_a
  end

  def remove_relations(absinthe_generator_structs, ecto_struct, relation_key) when is_atom(relation_key) do
    remove_relations(absinthe_generator_structs, ecto_struct, [relation_key])
  end

  def remove_relations(absinthe_generator_structs, ecto_struct, relation_key) when is_binary(relation_key) do
    remove_relations(absinthe_generator_structs, ecto_struct, [relation_key])
  end

  def remove_relations(absinthe_generator_structs, ecto_struct, relation_keys) do
    Enum.map(absinthe_generator_structs, fn
      %AbsintheGenerator.Type{} = type ->
        %{type |
          objects: Enum.map(type.objects, fn object ->
            %{object | fields: Enum.reject(object.fields, fn field ->
              (not is_nil(field.resolver) and
                object.name =~ EctoSchemaReflector.ecto_module_resource_name(ecto_struct) and
                field.name in Enum.map(relation_keys, &to_string/1))
            end)}
          end)
        }

      field -> field
    end)
  end
end
