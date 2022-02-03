defmodule PhoenixConfig do
  @moduledoc """
  My Moduledoc
  """

  alias PhoenixConfig.EctoSchemaReflector

  @type crud_from_schema_opts :: [
    only: list(:create | :all | :find | :update | :delete)
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
end
