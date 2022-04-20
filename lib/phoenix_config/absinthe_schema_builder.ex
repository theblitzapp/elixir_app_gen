defmodule PhoenixConfig.AbsintheSchemaBuilder do
  @moduledoc false

  alias Mix.PhoenixConfigHelpers

  @custom_types_regex ~r/\b(datetime|naive_datetime|date|time|decimal)\b/

  def generate(generation_item_tuples) do
    schema_struct = PhoenixConfigHelpers.app_name()
      |> AbsintheGenerator.SchemaBuilder.generate(
        Enum.map(generation_item_tuples, fn {generation_struct, _template} ->
          generation_struct
        end)
      )
      |> maybe_preprend_absinthe_custom_types(generation_item_tuples)

    generation_item_tuples
      |> Enum.sort_by(fn {%struct{}, _} -> struct end)
      |> Enum.concat([{schema_struct, AbsintheGenerator.run(schema_struct)}])
  end

  defp maybe_preprend_absinthe_custom_types(schema_struct, absinthe_generator_structs) do
    absinthe_custom_types? = Enum.any?(absinthe_generator_structs, fn
      {%AbsintheGenerator.Type{objects: objects}, _} ->
        Enum.any?(objects, &object_type_has_custom_type?/1)

      {%AbsintheGenerator.Mutation{mutations: mutations}, _} ->
        Enum.any?(mutations, &schema_field_has_custom_type?/1)

      {%AbsintheGenerator.Query{queries: queries}, _} ->
        Enum.any?(queries, &schema_field_has_custom_type?/1)

      _ -> false
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
end
