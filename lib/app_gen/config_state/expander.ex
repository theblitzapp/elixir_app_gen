defmodule AppGen.ConfigState.Expander do
  alias AppGen.{AbsintheTypeMerge, AbsintheSchemaBuilder}

  def expand(config_structs) do
    config_structs
    |> expand_crud_types
    |> pre_merge_types
    |> AbsintheSchemaBuilder.generate()
    |> run_config_functions
    |> AbsintheTypeMerge.maybe_merge_types()
  end

  defp pre_merge_types(generation_items) do
    {functions, generation_structs} = Enum.split_with(generation_items, &is_function/1)

    AbsintheTypeMerge.maybe_merge_types(generation_structs) ++ functions
  end

  defp expand_crud_types(generation_items) do
    Enum.flat_map(generation_items, fn
      %AbsintheGenerator.CrudResource{} = generation_item ->
        generation_item |> AbsintheGenerator.CrudResource.run() |> Enum.map(&elem(&1, 0))

      generation_item ->
        [generation_item]
    end)
  end

  defp run_config_functions(generation_items) do
    {config_functions, generation_structs} = Enum.split_with(generation_items, &is_function/1)

    Enum.reduce(config_functions, generation_structs, fn func, items_acc ->
      func.(items_acc)
    end)
  end
end
