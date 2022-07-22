defmodule AppConfig.EctoUtils do
  @moduledoc false

  require Logger

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
      _ ->
        raise to_string(IO.ANSI.format([
          :red, :bright, to_string(relation_name), :reset,
          :red, "doesn't exist on ", :bright, inspect(ecto_schema), :reset,
          :red, ", check your config for this key"
        ], true))
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

  def schema_relationship_list?(ecto_schema, relation_name) do
    case schema_association(ecto_schema, relation_name) do
      %{cardinality: :one} -> false
      %{cardinality: :many} -> true
      assication_record ->
        Logger.error("[AppConfig.EctoUtils] Error checking if schema #{ecto_schema} relationship #{relation_name} is a list\n#{inspect assication_record}")

        false
    end
  end
end
