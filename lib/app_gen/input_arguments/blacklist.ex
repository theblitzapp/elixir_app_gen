defmodule AppConfig.InputArguments.Blacklist do
  @moduledoc false

  alias AppConfig.InputArguments.Utils

  def run_option(blacklist_opts, absinthe_generator_structs, ecto_schema) do
    absinthe_generator_structs
      |> Utils.update_absinthe_schema_type_struct(
        ecto_schema,
        &blacklist_input_type_fields(&1, ecto_schema, blacklist_opts)
      )
      |> Utils.update_absinthe_schema_mutations_and_queries(
        ecto_schema,
        &(&1),
        &blacklist_query_arguments(&1, blacklist_opts)
      )
  end

  defp blacklist_input_type_fields(%AbsintheGenerator.Type{} = type_struct, ecto_schema, blacklist_fields) do
    Map.update!(
      type_struct,
      :objects,
      &remove_blacklisted_fields_from_objects(&1, ecto_schema, blacklist_fields)
    )
  end

  defp remove_blacklisted_fields_from_objects(objects, ecto_schema, blacklist_fields) do
    Enum.map(objects, fn
      %AbsintheGenerator.Type.Object{fields: fields, input?: true, name: name} = object ->
        case String.replace(name, ~r/_?#{Utils.ecto_schema_singular_input_type(ecto_schema)}/, "") do
          "" -> object
          crud_action ->
            crud_blacklist_fields = blacklist_fields[String.to_atom(crud_action)]

            if crud_blacklist_fields do
              crud_action_blacklist_fields = Enum.map(crud_blacklist_fields, &to_string/1)

              %{object | fields: Enum.reject(fields, &(&1.name in crud_action_blacklist_fields))}
            else
              object
            end
        end

      object -> object
    end)
  end

  defp blacklist_query_arguments(
    %AbsintheGenerator.Schema.Field{
      resolver_module_function: resolver_func
    } = schema_field,
    blacklist_opts
  ) do
    crud_action = Utils.resolver_function_crud_action(resolver_func)
    crud_blacklist_fields = blacklist_opts[String.to_atom(crud_action)]

    if is_nil(crud_blacklist_fields) or crud_blacklist_fields === [] do
      schema_field
    else
      crud_blacklist_fields = Enum.map(crud_blacklist_fields, &to_string/1)

      Map.update!(schema_field, :arguments, fn arguments ->
        Enum.reject(arguments, &(&1.name in crud_blacklist_fields))
      end)
    end
  end
end
