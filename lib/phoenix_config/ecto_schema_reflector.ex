defmodule PhoenixConfig.EctoSchemaReflector do
  def schema_relationship_types(ecto_schemas) do
    schema_fields = Map.new(ecto_schemas, &{&1, resolve_all_relation_schema_fields(&1)})

    Enum.flat_map(schema_fields, fn {schema, deep_relation_fields} ->
      deep_relation_fields
        |> Enum.filter(fn {relation_schema, _} -> relation_schema !== schema end)
        |> Enum.map(fn {relation_schema, {_resource_schema_fields, relation_fields}} ->
          field_name = module_name(relation_schema)

          build_type(relation_schema, [
            AbsintheGenerator.CrudResource.type_object(field_name, relation_fields)
          ])
        end)
    end)
  end

  defp build_type(schema, type_objects) do
    %AbsintheGenerator.Type{
      app_name: app_name(),
      type_name: module_name(schema),
      objects: type_objects
    }
  end

  defp resolve_all_relation_schema_fields(ecto_schema, acc \\ %{}) do
    relations = Enum.map(
      ecto_schema.__schema__(:associations),
      &ecto_schema.__schema__(:association, &1)
    )

    Enum.reduce(relations, acc, fn (%_{field: field, queryable: relation_schema}, acc) ->
      if acc[relation_schema] do
        Map.update!(acc, relation_schema, fn {fields, resource_fields} ->
          {Enum.uniq([{ecto_schema, field} | fields]), resource_fields}
        end)
      else
        resource_fields = generate_schema_fields(relation_schema) ++ generate_relation_fields(relation_schema)

        acc = Map.put(acc, relation_schema, {[{ecto_schema, field}], resource_fields})

        Map.merge(acc, resolve_all_relation_schema_fields(relation_schema, acc))
      end
    end)
  end

  def to_crud_resource(ecto_schema, only, except) do
    resource_fields = generate_schema_fields(ecto_schema) ++
      generate_relation_fields(ecto_schema)

    %AbsintheGenerator.CrudResource{
      app_name:  app_name(),
      resource_name: ecto_module_resource_name(ecto_schema),
      context_module: inspect(ecto_schema_context(ecto_schema)),
      only: only || [],
      except: except || [],
      resource_fields: resource_fields
    }
  end

  defp generate_relation_fields(ecto_schema) do
    relations = Enum.map(
      ecto_schema.__schema__(:associations),
      &{&1, ecto_schema.__schema__(:association, &1)}
    )

    Enum.map(relations, fn
      {
        field_name,
        %schema{queryable: queryable}
      } when schema in [Ecto.Association.BelongsTo, Ecto.Association.HasOne] ->
        {to_string(field_name), ":#{module_name(queryable)}", dataloader_string(queryable, field_name)}

      {field_name, %schema{queryable: queryable}} when schema in [Ecto.Association.Has, Ecto.Association.ManyToMany] ->
        {Inflex.pluralize(to_string(field_name)), "list_of(non_null(:#{module_name(queryable)}))", dataloader_string(queryable, field_name)}
    end)
  end

  def dataloader_string(ecto_schema, field_name) do
    "dataloader(#{ecto_schema |> ecto_schema_context |> inspect}, :#{field_name})"
  end

  def ecto_schema_context(ecto_schema) do
    ecto_schema |> Module.split |> Enum.drop(-1) |> Module.safe_concat

    rescue
      ArgumentError ->
        ecto_context = ecto_schema |> Module.split |> Enum.drop(-1) |> Enum.join(".")

        raise "Cannot find context module for #{inspect(ecto_context)}"
  end

  defp module_name(module) do
    module |> Module.split |> List.last |> Macro.underscore
  end

  defp generate_schema_fields(ecto_schema) do
    primary_keys = ecto_schema.__schema__(:primary_key)
    ecto_fields = ecto_schema.__schema__(:fields) -- primary_keys

    {primary_key, ecto_fields} = split_primary_key_and_fields(primary_keys, ecto_fields)

    [{to_string(primary_key), ":id"} | field_resources(ecto_schema.__changeset__, ecto_fields)]
  end

  defp field_resources(field_type_map, fields) do
    field_type_map
      |> Map.take(fields)
      |> Enum.map(fn {field_name, field_type} ->
        {to_string(field_name), to_string(maybe_convert_type(field_type))}
      end)
  end

  defp maybe_convert_type(:utc_datetime_usec), do: ":datetime"
  defp maybe_convert_type(:utc_datetime), do: ":datetime"
  defp maybe_convert_type(:naive_datetime_usec), do: ":datetime"
  defp maybe_convert_type(:naive_datetime), do: ":datetime"
  defp maybe_convert_type(:time_usec), do: ":datetime"
  defp maybe_convert_type({:array, type}), do: "list_of(non_null(#{maybe_convert_type(type)}))"
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

  defp app_name, do: Mix.Project.config[:app] |> to_string |> Macro.camelize
end
