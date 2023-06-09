defmodule AppGen.AbsintheSchemaBuilder do
  @moduledoc false

  alias Mix.AppGenHelpers

  @custom_types_regex ~r/\b(datetime|naive_datetime|date|time|decimal)\b/

  def generate(generation_structs) do
    {functions, generation_structs} = Enum.split_with(generation_structs, &is_function/1)

    schema_struct =
      AppGenHelpers.app_name()
      |> AbsintheGenerator.SchemaBuilder.generate(generation_structs)
      |> maybe_preprend_absinthe_custom_types(generation_structs)

    generation_structs
    |> Enum.sort_by(fn %struct{} -> struct end)
    |> Enum.concat([schema_struct | functions])
  end

  defp maybe_preprend_absinthe_custom_types(schema_struct, absinthe_generator_structs) do
    absinthe_custom_types? =
      Enum.any?(absinthe_generator_structs, fn
        %AbsintheGenerator.Type{objects: objects} ->
          Enum.any?(objects, &object_type_has_custom_type?/1)

        %AbsintheGenerator.Mutation{mutations: mutations} ->
          Enum.any?(mutations, &schema_field_has_custom_type?/1)

        %AbsintheGenerator.Query{queries: queries} ->
          Enum.any?(queries, &schema_field_has_custom_type?/1)

        _ ->
          false
      end)

    if absinthe_custom_types? do
      Map.update!(schema_struct, :types, &["Absinthe.Type.Custom" | &1])
    else
      schema_struct
    end
  end

  defp object_type_has_custom_type?(%AbsintheGenerator.Type.Object{fields: fields}) do
    Enum.any?(fields, fn %AbsintheGenerator.Type.Object.Field{type: type} ->
      to_string(type) =~ @custom_types_regex
    end)
  end

  defp schema_field_has_custom_type?(%AbsintheGenerator.Schema.Field{arguments: arguments}) do
    Enum.any?(arguments, fn %AbsintheGenerator.Schema.Field.Argument{type: type} ->
      to_string(type) =~ @custom_types_regex
    end)
  end

  def add_repo_to_data_source(absinthe_generator_structs, repo, contexts) do
    Enum.map(absinthe_generator_structs, fn
      %AbsintheGenerator.Schema{data_sources: data_sources} = schema ->
        %{schema | data_sources: add_repo_to_data_sources(data_sources, repo, contexts)}

      generator_struct ->
        generator_struct
    end)
  end

  defp add_repo_to_data_sources(data_sources, repo, contexts) do
    Enum.reduce(contexts, data_sources, fn context, data_source_acc ->
      Enum.map(data_source_acc, fn %AbsintheGenerator.Schema.DataSource{} = data_source ->
        if data_source.source === inspect(context) do
          %{data_source | query: String.replace(data_source.query, "\"<REPO>\"", inspect(repo))}
        else
          data_source
        end
      end)
    end)
  end

  def add_post_middleware_to_schema(absinthe_generator_structs, middleware_opts) do
    Enum.map(absinthe_generator_structs, fn
      %AbsintheGenerator.Schema{} = schema ->
        middleware = convert_to_middleware_params(middleware_opts)

        %{schema | post_middleware: middleware ++ schema.post_middleware}

      generator_struct ->
        generator_struct
    end)
  end

  def add_pre_middleware_to_schema(absinthe_generator_structs, middleware_opts) do
    Enum.map(absinthe_generator_structs, fn
      %AbsintheGenerator.Schema{} = schema ->
        middleware = convert_to_middleware_params(middleware_opts)

        %{schema | pre_middleware: middleware ++ schema.pre_middleware}

      generator_struct ->
        generator_struct
    end)
  end

  defp convert_to_middleware_params(middleware_opts) do
    middleware_opts
    |> Enum.flat_map(fn {middlware_type, modules} ->
      Enum.map(modules, &{middlware_type, &1})
    end)
    |> Enum.group_by(
      fn {_middlware_type, module} -> module end,
      fn {middlware_type, _module} -> middlware_type end
    )
    |> Enum.map(fn {middleware_module, middleware_types} ->
      %AbsintheGenerator.Schema.Middleware{
        module: middleware_module,
        types: middleware_types
      }
    end)
  end
end
