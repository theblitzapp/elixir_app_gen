defmodule PhoenixConfig.InputArguments.Required do
  @moduledoc false

  alias PhoenixConfig.InputArguments.Utils

  @mutation_actions AbsintheGenerator.CrudResource.mutation_crud_types()

  def run_option(required_opts, absinthe_generator_structs, ecto_schema, crud_options) do
    absinthe_generator_structs
      |> Utils.update_absinthe_schema_type_struct(ecto_schema, fn
        %AbsintheGenerator.Type{objects: objects} = type ->
          %{type |
            objects: split_singular_type_into_multiple(
              objects,
              absinthe_generator_structs,
              ecto_schema,
              required_opts,
              crud_options
            )
          }
      end)
      |> Utils.update_absinthe_schema_mutations_and_queries(
        ecto_schema,
        &update_mutation_fields(ecto_schema, crud_options, &1),
        &update_query_fields(crud_options, &1)
      )
  end

  defp update_mutation_fields(ecto_schema, crud_options, %AbsintheGenerator.Schema.Field{
    resolver_module_function: resolver_function,
    arguments: arguments,
  } = field) do
    crud_action = Utils.resolver_function_crud_action(resolver_function)

    if crud_action in Utils.crud_fields_from_opts(crud_options) do
      %{field | arguments: replace_schema_field_arguments_with_crud_input(arguments, ecto_schema, crud_action)}
    else
      field
    end
  end

  defp update_query_fields(crud_options, %AbsintheGenerator.Schema.Field{
    resolver_module_function: resolver_function,
    arguments: arguments,
  } = field) do
    crud_action = resolver_function |> Utils.resolver_function_crud_action() |> String.to_atom
    required_fields = Enum.map(crud_options[:required][crud_action] || [], &to_string/1)
    blacklist_non_required? = crud_options[:blacklist_non_required?][crud_action] || false

    arguments = Enum.map(arguments, fn argument ->
      if argument.name in required_fields do
        AbsintheGenerator.Schema.Field.maybe_add_non_null_argument(argument)
      else
        argument
      end
    end)

    if blacklist_non_required? do
      %{field | arguments: filter_required_arguments(arguments)}
    else
      %{field | arguments: arguments}
    end
  end

  defp filter_required_arguments(arguments) do
    Enum.filter(arguments, fn %AbsintheGenerator.Schema.Field.Argument{type: type} ->
      type =~ ~r/^non_null/
    end)
  end

  defp split_singular_type_into_multiple(objects, absinthe_generator_structs, ecto_schema, required_opts, crud_options) do
    case split_input_object(objects, ecto_schema) do
      {nil, _} ->
        module_name = Utils.ecto_schema_module_underscore_name(ecto_schema)

        raise to_string(IO.ANSI.format([
          "Somehow got nil when looking for ", :bright,  "#{module_name}_input", :reset,
          :red, " for ", :bright, "required ", :reset,
          :red, "arg"
        ], true))

      {[input_type], other_objects} ->
        new_input_types = generate_required_crud_input_types(input_type, required_opts, ecto_schema, crud_options)

        other_objects ++ new_input_types ++ maybe_leave_input_type(input_type, absinthe_generator_structs, ecto_schema, crud_options)
    end
  end

  defp split_input_object(objects, ecto_schema) do
    Enum.split_with(objects, &(&1.name === Utils.ecto_schema_singular_input_type(ecto_schema)))
  end

  defp generate_required_crud_input_types(input_type, required_opts, ecto_schema, crud_options) do
    required_opts
      |> Enum.filter(fn {crud_action, _} -> crud_action in @mutation_actions end)
      |> Enum.map(fn {crud_action, crud_required_fields} ->
        %{AbsintheGenerator.CrudResource.type_object(
          "#{crud_action}_#{Utils.ecto_schema_module_underscore_name(ecto_schema)}_input",
          modify_required_fields(
            input_type.fields,
            crud_required_fields,
            crud_options[:blacklist_non_required?][crud_action]
          )
        ) | input?: true}
      end)
  end

  defp modify_required_fields(fields, crud_required_fields, true) do
    crud_required_fields = Enum.map(crud_required_fields, &to_string/1)

    fields
      |> Enum.filter(fn %AbsintheGenerator.Type.Object.Field{name: name} ->
        name in crud_required_fields
      end)
      |> add_non_null_to_required_fields(crud_required_fields)
      |> maybe_add_required_id_field(crud_required_fields)
  end

  defp modify_required_fields(fields, crud_required_fields, _blacklist_non_required?) do
    fields
      |> add_non_null_to_required_fields(crud_required_fields)
      |> maybe_add_required_id_field(crud_required_fields)
  end

  defp add_non_null_to_required_fields(fields, non_null_fields) do
    non_null_fields = Enum.map(non_null_fields, &to_string/1)

    Enum.map(fields, fn %AbsintheGenerator.Type.Object.Field{} = field ->
      if field.name in non_null_fields do
        AbsintheGenerator.Type.maybe_add_non_null(field)
      else
        field
      end
    end)
  end

  # We need to do this because ID is not a field we put on in the first place due to it not being updatable
  defp maybe_add_required_id_field(fields, crud_required_fields) do
    if "id" in crud_required_fields do
      case Enum.find(fields, &(&1 === "id")) do
        nil -> [%AbsintheGenerator.Type.Object.Field{type: "non_null(:id)", name: "id"} | fields]
        _ -> fields
      end
    else
      fields
    end
  end

  defp maybe_leave_input_type(input_type, absinthe_generator_structs, ecto_schema, crud_options) do
    if generator_structs_require_singular_type?(ecto_schema, crud_options, absinthe_generator_structs) do
      [input_type]
    else
      []
    end
  end

  defp generator_structs_require_singular_type?(ecto_schema, crud_options, absinthe_generator_structs) do
    schema_module_name = Utils.ecto_schema_module_name(ecto_schema)
    crud_fields_in_opts = Utils.crud_fields_from_opts(crud_options)

    !Enum.all?(absinthe_generator_structs, fn
      %AbsintheGenerator.Mutation{mutation_name: ^schema_module_name, mutations: mutations} ->
        all_schema_fields_in_args?(mutations, crud_fields_in_opts)

      %AbsintheGenerator.Query{query_name: ^schema_module_name, queries: queries} ->
        all_schema_fields_in_args?(queries, crud_fields_in_opts)

      _generator_struct -> true
    end)
  end

  defp all_schema_fields_in_args?(schema_fields, crud_fields_in_opts) do
    Enum.all?(
      schema_fields,
      &Utils.resolver_function_crud_action(&1.resolver_module_function) in crud_fields_in_opts
    )
  end

  defp replace_schema_field_arguments_with_crud_input(arguments, ecto_schema, crud_action) do
    singular_input_type = Utils.ecto_schema_singular_input_type(ecto_schema)
    Enum.map(arguments, fn
      %AbsintheGenerator.Schema.Field.Argument{type: type} = field_arg ->
        if type =~ ":#{singular_input_type}" do
          %{field_arg |
            type: "non_null(:#{crud_action}_#{singular_input_type})"
          }
        else
          field_arg
        end

      field_arg -> field_arg
    end)
  end
end
