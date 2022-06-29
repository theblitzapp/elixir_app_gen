defmodule PhoenixConfig.PhoenixConfig.Support.Accounts do
  alias EctoShorts.Actions

  alias PhoenixConfig.Support.Accounts.User

  def create_user(params) do
    Actions.create(User, params)
  end

  def find_user(params) do
    Actions.find(User, params)
  end

  def all_users(params \\ %{}) do
    Actions.all(User, params)
  end

  def update_user(id_or_schema, params) do
    Actions.update(User, id_or_schema, params)
  end

  def delete_user(id_or_schema) do
    Actions.delete(User, id_or_schema)
  end

  def find_and_update_or_create_user(params, update_params) do
    Actions.find_and_update(User, params, update_params)
  end
end