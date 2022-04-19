defmodule PhoenixConfig.InputArguments.Utils do
  require Logger

  def crud_fields_from_opts(crud_options) do
    crud_options
      |> Keyword.values
      |> Enum.flat_map(&Keyword.keys(&1))
      |> Enum.map(&to_string/1)
      |> Enum.uniq
  end

  def resolver_function_crud_action(resolver_module_function) do
    case Regex.run(~r/Resolvers\.[[:alpha:]]+\.([^\/]+)/, resolver_module_function, capture: :all_but_first) do
      ["all"] -> "index"
      [crud_action] -> crud_action

      _ ->
        Logger.warn("[PhoenixConfig.InputArgumentsReflector] Couldn't find crud action for resolver: #{resolver_module_function}")

        nil
    end
  end

  def update_absinthe_schema_mutations_and_queries(absinthe_generator_structs, ecto_schema, update_mutations_fn, update_queries_fn) do
    schema_module_name = ecto_schema_module_name(ecto_schema)

    Enum.map(absinthe_generator_structs, fn
      %AbsintheGenerator.Mutation{mutation_name: ^schema_module_name, mutations: mutations} = generator_struct ->
        %{generator_struct | mutations: Enum.map(mutations, update_mutations_fn)}

      %AbsintheGenerator.Query{query_name: ^schema_module_name, queries: queries} = generator_struct ->
        %{generator_struct | queries: Enum.map(queries, update_queries_fn)}

      generator_struct -> generator_struct
    end)
  end

  def update_absinthe_schema_type_struct(absinthe_generator_structs, ecto_schema, update_fn) do
    case Enum.find_index(
      absinthe_generator_structs,
      &(&1.type_name === ecto_schema_module_underscore_name(ecto_schema))
    ) do
      nil ->
        Logger.error("[PhoenixConfig.InputArgumentsReflector] Can't find type struct for #{ecto_schema}")

        absinthe_generator_structs

      index -> update_in(
        absinthe_generator_structs,
        [Access.at!(index)],
        update_fn
      )
    end
  end

  def ecto_schema_singular_input_type(ecto_schema) do
    "#{ecto_schema_module_underscore_name(ecto_schema)}_input"
  end

  def ecto_schema_module_name(ecto_schema) do
    ecto_schema |> Module.split |> List.last
  end

  def ecto_schema_module_underscore_name(ecto_schema) do
    ecto_schema |> ecto_schema_module_name |> Macro.underscore
  end
end
