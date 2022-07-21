defmodule PhoenixConfig do
  @moduledoc """
  #{File.read!("./README.md")}
  """

  alias PhoenixConfig.{
    AbsintheSchemaBuilder,
    AbsintheTypeMerge,
    EctoSchemaReflector,
    InputArguments
  }

  @type arg_opts :: [
    required: list(atom),
    blacklist: list(atom),
    blacklist_non_required?: boolean,
    relation_inputs: list(atom)
  ]

  @type crud_from_schema_opts :: [
    only: list(AbsintheGenerator.CrudResource.crud_type),
    except: list(AbsintheGenerator.CrudResource.crud_type),
    input_args: [
      create: arg_opts,
      find: arg_opts,
      all: arg_opts,
      update: arg_opts,
      delete: arg_opts,
      find_and_update_or_create: arg_opts
    ]
  ]

  @type middleware_opts :: [
    subscription: list(module),
    query: list(module),
    mutation: list(module),
    all: list(module)
  ]

  def moduledoc, do: @moduledoc

  def crud_from_schema(ecto_schema, opts \\ []) do
    relation_types = EctoSchemaReflector.schema_relationship_types([ecto_schema])
    crud_resouce = EctoSchemaReflector.to_crud_resource(
      ecto_schema,
      opts[:only],
      opts[:except]
    )

    schema_types = [crud_resouce | relation_types]

    if opts[:input_args] do
      schema_types ++ [&InputArguments.change_crud_input_args(
        &1,
        ecto_schema,
        opts[:input_args]
      )]
    else
      schema_types
    end
  end

  def remove_relations(ecto_schema, relation_key) do
    &AbsintheTypeMerge.remove_relations(&1, ecto_schema, relation_key)
  end

  def post_middleware(middleware_opts) do
    &AbsintheSchemaBuilder.add_post_middleware_to_schema(&1, middleware_opts)
  end

  def pre_middleware(middleware_opts) do
    &AbsintheSchemaBuilder.add_pre_middleware_to_schema(&1, middleware_opts)
  end

  def repo_contexts(repo, contexts) when is_list(contexts) do
    &AbsintheSchemaBuilder.add_repo_to_data_source(&1, repo, contexts)
  end

  def repo_contexts(repo, context) do
    repo_contexts(repo, [context])
  end
end
