defmodule PhoenixConfig.AbsintheTypeMerge do
  def maybe_merge_types(absinthe_generator_schemas) do
    absinthe_generator_schemas
  end

  def remove_relation(absinthe_generator_schemas, _ecto_schema, _relation_key) do
    absinthe_generator_schemas
  end
end
