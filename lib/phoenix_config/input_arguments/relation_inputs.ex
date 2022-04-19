defmodule PhoenixConfig.InputArguments.RelationInputs do
  @moduledoc """
  This module takes in relations in the format of
  - :relation
  - [relation: :sub_relation]
  - [relation: [required: [:field_a, :field_b], blacklist_non_required?: true]]
  - [:relation_one, :relation_two]
  - [:relation_one, relation_two: [:relation_three, :relation_four]]
  - [:relation_one, relation_two: {[required: [:field_a, :field_b], blacklist_non_required?: true], [:relation_three, relation_four]}]

  Using these arguments it modifies types to create input types for
  the relations specified with the args for that relation

  Supported arguments for the relations include `required`, `blacklist` and `blacklist_non_required?`
  """

  require Logger

  alias PhoenixConfig.{EctoUtils, AbsintheUtils}
  alias PhoenixConfig.InputArguments.Utils

  @arg_names PhoenixConfig.InputArguments.arg_names() -- [:relation_inputs]

  def run_option(crud_relation_inputs, ecto_schema, absinthe_generator_structs) do
    Enum.reduce(crud_relation_inputs, absinthe_generator_structs, fn
      {crud_action, relation_inputs}, acc_gen_structs ->
        run_crud_option(relation_inputs, crud_action, ecto_schema, acc_gen_structs)
    end)
  end

  defp run_crud_option(relation_input, crud_action, ecto_schema, absinthe_generator_structs) when is_atom(relation_input) do
    run_crud_option([relation_input], crud_action, ecto_schema, absinthe_generator_structs)
  end

  defp run_crud_option(relation_inputs, crud_action, ecto_schema, absinthe_generator_structs) do
    Enum.reduce(
      relation_inputs,
      absinthe_generator_structs,
      &reduce_relation_input(&1, &2, crud_action, ecto_schema)
    )
  end

  defp reduce_relation_input(relation_name, absinthe_generator_structs, crud_action, ecto_schema) when is_atom(relation_name) do
    add_relational_input_type(absinthe_generator_structs, crud_action, ecto_schema, relation_name)
  end

  defp reduce_relation_input(
    {relation_name, sub_relation_input},
    absinthe_generator_structs,
    crud_action,
    ecto_schema
  ) when is_atom(sub_relation_input) do
    relation_name
      |> reduce_relation_input(absinthe_generator_structs, crud_action, ecto_schema)
      |> then(&reduce_relation_input(
        sub_relation_input,
        &1,
        crud_action,
        {ecto_schema, EctoUtils.schema_association_module(ecto_schema, relation_name)}
      ))
  end

  defp reduce_relation_input(
    {relation_name, sub_relation_inputs_or_relation_args},
    absinthe_generator_structs,
    crud_action,
    ecto_schema
  ) when is_list(sub_relation_inputs_or_relation_args) do
    if arg_opts?(sub_relation_inputs_or_relation_args) do
      add_relational_input_type_with_args(
        absinthe_generator_structs,
        crud_action,
        ecto_schema,
        relation_name,
        sub_relation_inputs_or_relation_args
      )
    else
      run_option(
        [{crud_action, sub_relation_inputs_or_relation_args}],
        {ecto_schema, EctoUtils.schema_association_module(ecto_schema, relation_name)},
        absinthe_generator_structs
      )
    end
  end

  defp reduce_relation_input(
    {relation_name, {relation_args, sub_relation_inputs}},
    absinthe_generator_structs,
    crud_action,
    ecto_schema
  ) do
    absinthe_generator_structs
      |> add_relational_input_type_with_args(
        crud_action,
        ecto_schema,
        relation_name,
        relation_args
      )
      |> then(&run_option(
        [{crud_action, sub_relation_inputs}],
        {ecto_schema, EctoUtils.schema_association_module(ecto_schema, relation_name)},
        &1
      ))
  end

  defp add_relational_input_type(absinthe_generator_structs, crud_action, ecto_schema, relation_name) do
    current_schema = current_ecto_schema(ecto_schema)
    type_name = ecto_schema_input_type_name(crud_action, ecto_schema, relation_name)
    relation_schema = EctoUtils.schema_association_module(current_schema, relation_name)

    Utils.update_absinthe_schema_type_struct(absinthe_generator_structs, root_ecto_schema(ecto_schema), fn
      %AbsintheGenerator.Type{} = type_struct ->
        type_struct
          |> Map.update!(
            :objects,
            &generate_and_append_object_type_struct(&1, type_name, crud_action, relation_schema, [])
          )
          |> Map.update!(
            :objects,
            &add_input_type_to_parent(&1, type_name, relation_name)
          )
    end)
  end

  defp add_relational_input_type_with_args(
    absinthe_generator_structs,
    crud_action,
    ecto_schema,
    relation_name,
    relation_args
  ) do
    current_schema = current_ecto_schema(ecto_schema)
    type_name = ecto_schema_input_type_name(crud_action, ecto_schema, relation_name)
    relation_schema = EctoUtils.schema_association_module(current_schema, relation_name)

    Utils.update_absinthe_schema_type_struct(absinthe_generator_structs, root_ecto_schema(ecto_schema), fn
      %AbsintheGenerator.Type{} = type_struct ->
        type_struct
          |> Map.update!(
            :objects,
            &generate_and_append_object_type_struct(&1, type_name, crud_action, relation_schema, relation_args)
          )
          |> Map.update!(
            :objects,
            &add_input_type_to_parent(&1, type_name, relation_name)
          )
    end)
  end

  defp ecto_schema_input_type_name(crud_action, ecto_schema, relation_name) do
    ecto_type_name = build_ecto_schema_type_name(ecto_schema)

    "#{crud_action}_#{ecto_type_name}_#{Inflex.singularize(relation_name)}_input"
  end

  defp build_ecto_schema_type_name({parent_schema_or_schemas, ecto_schema}) do
    build_ecto_schema_type_name(parent_schema_or_schemas) <>
    "_" <>
    build_ecto_schema_type_name(ecto_schema)
  end

  defp build_ecto_schema_type_name(ecto_schema) do
    EctoUtils.schema_module_resource_name(ecto_schema)
  end

  defp generate_and_append_object_type_struct(type_object_structs, type_name, crud_action, ecto_schema, relation_args) do
    type_object_structs ++ [%AbsintheGenerator.Type.Object{
      name: type_name,
      input?: true,
      fields: generate_type_object_fields(type_name, ecto_schema, crud_action, relation_args)
    }]
  end

  defp generate_type_object_fields(type_name, ecto_schema, crud_action, relation_args) do
    ecto_schema.__changeset__()
      |> Map.take(parse_schema_field_keys_with_args(type_name, ecto_schema, crud_action, relation_args))
      |> Enum.map(fn {field, type} ->
        field_struct = %AbsintheGenerator.Type.Object.Field{
          name: to_string(field),
          type: AbsintheUtils.normalize_ecto_type(type)
        }

        if relation_args[:required] && field in relation_args[:required] do
          AbsintheGenerator.Type.maybe_add_non_null(field_struct)
        else
          field_struct
        end
      end)
  end

  defp parse_schema_field_keys_with_args(_, ecto_schema, crud_action, []) do
    filtered_schema_fields(ecto_schema, crud_action)
  end

  defp parse_schema_field_keys_with_args(type_name, ecto_schema, crud_action, relation_args) do
    fields = filtered_schema_fields(ecto_schema, crud_action) -- (relation_args[:blacklist] || [])

    cond do
      relation_args[:blacklist_non_required?] && !relation_args[:required] ->
        Logger.error("[PhoenixConfig.InputArguments.RelationInputs] :blacklist_non_required? is set for #{type_name} but no :required keys found")

        fields

      !relation_args[:required] -> fields

      true -> EctoUtils.fields_intersection(fields, relation_args[:required])
    end
  end

  def filtered_schema_fields(ecto_schema, crud_action) do
    blacklist_types = AbsintheUtils.blacklist_input_types() ++ (if crud_action === :create, do: [:id], else: [])

    EctoUtils.schema_fields(ecto_schema) -- blacklist_types
  end

  def add_input_type_to_parent(type_object_structs, type_name, relation_name) do
    parent_object_type_name = String.replace(type_name, "_#{relation_name}", "")

    Enum.map(type_object_structs, fn
      %AbsintheGenerator.Type.Object{name: ^parent_object_type_name} = object_struct ->
        Map.update!(object_struct, :fields, fn fields ->
          fields ++ [%AbsintheGenerator.Type.Object.Field{
            name: to_string(relation_name),
            type: type_name
          }]
        end)

      type_struct -> type_struct
    end)
  end

  defp arg_opts?(args) do
    Enum.all?(args, fn
      {arg_name, _value} when arg_name in @arg_names -> true
      _ -> false
    end)
  end

  defp current_ecto_schema({_parent_schema, ecto_schema}), do: current_ecto_schema(ecto_schema)
  defp current_ecto_schema(ecto_schema), do: ecto_schema

  defp root_ecto_schema({parent_schema, _ecto_schema}), do: root_ecto_schema(parent_schema)
  defp root_ecto_schema(ecto_schema), do: ecto_schema
end
