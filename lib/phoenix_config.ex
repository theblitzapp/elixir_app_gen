defmodule PhoenixConfig do
  @moduledoc """
  My Moduledoc
  """

  alias PhoenixConfig.EctoSchemaReflector

  def moduledoc, do: @moduledoc

  def crud_from_schema(ecto_context_module, ecto_schema, opts \\ []) do
    relation_types = EctoSchemaReflector.schema_relationship_types([ecto_schema])
    crud_resouce = EctoSchemaReflector.to_crud_resource(
      ecto_context_module,
      ecto_schema,
      opts[:only],
      opts[:except]
    )

    [crud_resouce | relation_types]
  end
end
