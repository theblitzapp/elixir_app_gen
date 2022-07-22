defmodule AppConfig.AbsintheTypeMerge do
  @moduledoc false

  alias AppConfig.EctoSchemaReflector

  def maybe_merge_types(absinthe_generator_structs) do
    {non_type_structs, duplicate_type_structs_map} = absinthe_generator_structs
      |> Enum.group_by(&absinthe_generator_struct_type_name/1)
      |> Map.pop(nil)

    duplicate_type_structs_map
      |> resolve_duplicate_types
      |> Enum.concat(non_type_structs)
  end

  defp absinthe_generator_struct_type_name(%AbsintheGenerator.Type{type_name: type_name}) do
    type_name
  end

  defp absinthe_generator_struct_type_name(_), do: nil

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
          objects: merge_type_objects(acc_type_struct.type_name, acc_type_struct.objects, type_struct.objects)
        }
    end)

    merged_type_struct
  end

  defp merge_type_objects(type_name, type_objects, duplicate_type_objects) do
    Enum.reduce(duplicate_type_objects, type_objects, fn type_obj, type_objects_acc ->
      case Enum.find(type_objects_acc, &(&1.name === type_obj.name)) do
        nil -> [type_obj | type_objects_acc]

        duplicate_type ->
          Enum.map(type_objects_acc, fn
            ^duplicate_type -> merge_duplicate_type_object(type_name, type_obj, duplicate_type)
            type_object -> type_object
          end)
      end
    end)
  end

  def merge_duplicate_type_object(
    type_name,
    %AbsintheGenerator.Type.Object{fields: fields},
    %AbsintheGenerator.Type.Object{fields: other_fields} = duplicate_type_obj
  ) do
    resolved_fields = fields
      |> Enum.concat(other_fields)
      |> Enum.group_by(&(&1.name))
      |> Enum.map(fn {_name, fields} ->
        Enum.reduce(fields, fn field_a, field_b ->
          cond do
            is_nil(field_a.resolver) and not is_nil(field_b.resolver) -> field_b
            is_nil(field_b.resolver) and not is_nil(field_a.resolver) -> field_a
            field_a.type =~ ~r/list/ and not (field_b.type =~ ~r/list/) ->
              raise IO.ANSI.format([
                :red, "Found two duplicate types for #{type_name}, one with list and one without", :reset,
                :orange, "\nA: #{inspect(field_a)}", "\nB: #{inspect(field_b)}"
              ])

            field_a.type =~ ~r/non_null/ -> field_a
            field_a.type === field_b.type -> field_b

            true ->
              raise IO.ANSI.format([
                :red, "Found two duplicate #{field_a.name} for #{type_name} with different types", :reset,
                :orange, "\nType A: #{inspect(field_a.type)}", "\nType B: #{inspect(field_b.type)}"
              ])
          end
        end)
      end)

    %{duplicate_type_obj | fields: resolved_fields}
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
