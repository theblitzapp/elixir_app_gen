defmodule PhoenixConfig.EctoSchemaReflector do
  def to_resource(ecto_context_module, ecto_schema, only, except) do
    resource_fields = generate_resource_fields(ecto_schema)

    %AbsintheGenerator.CrudResource{
      app_name: Mix.Project.config[:app] |> to_string |> Macro.camelize,
      resource_name: ecto_module_resource_name(ecto_schema),
      context_module: ecto_context_module,
      only: only,
      except: except,
      resource_fields: resource_fields
    }
  end

  defp generate_resource_fields(ecto_schema) do
    primary_keys = ecto_schema.__schema__(:primary_key)
    ecto_fields = ecto_schema.__schema__(:fields) -- primary_keys

    {primary_key, ecto_fields} = split_primary_key_and_fields(primary_keys, ecto_fields)

    [{to_string(primary_key), ":id"} | field_resources(ecto_schema.__changeset__, ecto_fields)]
  end

  defp field_resources(field_type_map, fields) do
    field_type_map
      |> Map.take(fields)
      |> Enum.map(fn {field_name, field_type} ->
        {to_string(field_name), inspect(maybe_convert_type(field_type))}
      end)
  end

  defp maybe_convert_type(:utc_datetime_usec), do: :datetime
  defp maybe_convert_type(:utc_datetime), do: :datetime
  defp maybe_convert_type(:naive_datetime_usec), do: :datetime
  defp maybe_convert_type(:naive_datetime), do: :datetime
  defp maybe_convert_type(:time_usec), do: :datetime
  defp maybe_convert_type(type), do: type

  defp split_primary_key_and_fields(primary_keys, ecto_fields) do
    if length(primary_keys) > 1 do
      primary_key = hd(primary_keys)
      ecto_fields = tl(primary_keys) ++ ecto_fields

      {primary_key, ecto_fields}
    else
      {hd(primary_keys), ecto_fields}
    end
  end

  def ecto_module_resource_name(ecto_context_module) do
    ecto_context_module
      |> to_string
      |> String.split(".")
      |> List.last
      |> Macro.underscore
  end
end
