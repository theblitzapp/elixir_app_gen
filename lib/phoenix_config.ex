defmodule PhoenixConfig do
  @moduledoc """
  My Moduledoc
  """

  def moduledoc, do: @moduledoc

  def crud_from_schema(ecto_context_module, ecto_schema, opts \\ []) do
    PhoenixConfig.EctoSchemaReflector.to_resource(ecto_context_module, ecto_schema, opts[:only], opts[:except])
  end
end
