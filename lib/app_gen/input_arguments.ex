defmodule AppGen.InputArguments do
  @moduledoc false

  require Logger

  alias AppGen.InputArguments

  @arg_names [:blacklist, :required, :blacklist_non_required?, :relation_inputs]

  def arg_names, do: @arg_names

  def change_crud_input_args(absinthe_generator_structs, ecto_schema, input_args_opts) do
    crud_options =
      input_args_opts
      |> collect_args_by_name
      |> sort_arg_priority

    Enum.reduce(
      crud_options,
      absinthe_generator_structs,
      &reduce_crud_options(&1, ecto_schema, crud_options, &2)
    )
  end

  defp sort_arg_priority(crud_options) do
    Enum.sort_by(crud_options, fn
      {:blacklist, _} -> 2
      {:required, _} -> 1
      {:blacklist_non_required?, _} -> 0
      {_, _} -> 4
    end)
  end

  defp collect_args_by_name(input_args_opts) do
    Enum.reduce(input_args_opts, [], fn {crud_action, opts}, args_acc ->
      Enum.reduce(opts, args_acc, fn {opt_name, opt_value}, opts_args_acc ->
        Keyword.update(opts_args_acc, opt_name, [{crud_action, opt_value}], fn opts ->
          [{crud_action, opt_value} | opts]
        end)
      end)
    end)
  end

  defp reduce_crud_options(
         {:required, required_opts},
         ecto_schema,
         crud_options,
         absinthe_generator_structs
       ) do
    InputArguments.Required.run_option(
      required_opts,
      absinthe_generator_structs,
      ecto_schema,
      crud_options
    )
  end

  defp reduce_crud_options(
         {:blacklist, blacklist_opts},
         ecto_schema,
         _crud_options,
         absinthe_generator_structs
       ) do
    InputArguments.Blacklist.run_option(blacklist_opts, absinthe_generator_structs, ecto_schema)
  end

  defp reduce_crud_options(
         {:blacklist_non_required?, non_required_opts},
         ecto_schema,
         crud_options,
         absinthe_generator_structs
       ) do
    Enum.each(non_required_opts, fn
      {crud_action, true} ->
        required_value = crud_options[:required][crud_action]

        if is_nil(required_value) or required_value === [] do
          raise to_string(
                  IO.ANSI.format(
                    [
                      :red,
                      "Must supply ",
                      :bright,
                      "required",
                      :reset,
                      :red,
                      " key for CRUD options for ",
                      :bright,
                      inspect(ecto_schema),
                      :reset,
                      :red,
                      " when using ",
                      :bright,
                      "blacklist_non_required?"
                    ],
                    true
                  )
                )
        end

      {crud_action, _} ->
        raise to_string(
                IO.ANSI.format(
                  [
                    :red,
                    "Remove key ",
                    :bright,
                    "blacklist_non_required?",
                    :reset,
                    :red,
                    " from ",
                    :bright,
                    inspect(ecto_schema),
                    :reset,
                    :red,
                    " for ",
                    :bright,
                    to_string(crud_action),
                    :reset,
                    :red,
                    " action instead of setting to false"
                  ],
                  true
                )
              )
    end)

    absinthe_generator_structs
  end

  defp reduce_crud_options(
         {:relation_inputs, relation_inputs},
         ecto_schema,
         _crud_options,
         absinthe_generator_structs
       ) do
    InputArguments.RelationInputs.run_option(
      relation_inputs,
      ecto_schema,
      absinthe_generator_structs
    )
  end
end
