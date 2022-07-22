defmodule PhoenixConfig.AbsintheUtils do
  @moduledoc false

  def blacklist_input_types, do: [:inserted_at, :updated_at]

  def normalize_ecto_type(:utc_datetime_usec), do: ":datetime"
  def normalize_ecto_type(:utc_datetime), do: ":datetime"
  def normalize_ecto_type(:naive_datetime_usec), do: ":naive_datetime"
  def normalize_ecto_type(:naive_datetime), do: ":naive_datetime"
  def normalize_ecto_type(:time_usec), do: ":datetime"
  def normalize_ecto_type({:array, type}), do: "list_of(non_null(#{normalize_ecto_type(type)}))"
  def normalize_ecto_type(type), do: AbsintheGenerator.Type.maybe_string_atomize_type(inspect(type))
end
