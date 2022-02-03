defmodule PhoenixConfig do
  @moduledoc """
  My Moduledoc
  """

  alias PhoenixConfig.{EctoSchemaReflector, AbsintheTypeMerge}

  @type crud_from_schema_opts :: [
    only: list(AbsintheGenerator.CrudResource.crud_type),
    except: list(AbsintheGenerator.CrudResource.crud_type)
  ]

  def moduledoc, do: @moduledoc

  def crud_from_schema(ecto_schema, opts \\ []) do
    relation_types = EctoSchemaReflector.schema_relationship_types([ecto_schema])
    crud_resouce = EctoSchemaReflector.to_crud_resource(
      ecto_schema,
      opts[:only],
      opts[:except]
    )

    [crud_resouce | relation_types]
  end

  def exclude_relation(ecto_schema, relation_key) do
    &AbsintheTypeMerge.remove_relation(&1, ecto_schema, relation_key)
  end
end
