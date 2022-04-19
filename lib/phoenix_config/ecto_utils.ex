defmodule PhoenixConfig.EctoUtils do
  def schema_primary_key(ecto_schema) do
    ecto_schema.__schema__(:primary_key)
  end

  def schema_fields(ecto_schema) do
    ecto_schema.__schema__(:fields)
  end

  def schema_associations(ecto_schema) do
    ecto_schema.__schema__(:associations)
  end

  def schema_association(ecto_schema, relation_name) do
    ecto_schema.__schema__(:association, relation_name)
  end

  def schema_association_module(ecto_schema, relation_name) do
    case schema_association(ecto_schema, relation_name) do
      %{queryable: queryable} -> queryable
      _ -> nil
    end
  end

  def schema_module(ecto_schema) do
    ecto_schema
      |> Module.split
      |> List.last
  end

  def schema_module_resource_name(ecto_schema) do
    ecto_schema
      |> schema_module
      |> Macro.underscore
  end

  def fields_intersection(fields_a, fields_b) do
    fields_a
      |> MapSet.new
      |> MapSet.intersection(MapSet.new(fields_b))
      |> MapSet.to_list
  end
end
