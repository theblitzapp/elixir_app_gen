defmodule AppConfig.AppConfig.Support.AccountsTest do
  use AppConfig.DataCase, async: true

  alias AppConfig.AppConfig.Support.Accounts.Support.Factory

  alias AppConfig.AppConfig.Support.Accounts

  # User Tests

  describe "&create_user/1" do
    test "creates a module with proper required fields" do
      params = FactoryEx.build(Factory.User)

      assert {:ok, result} = AppConfig.Support.Accounts.create_user(params)

      assert Map.drop(result, [:__struct__, :__meta__]) === params
    end
  end

  describe "&find_user/1" do
    test "finds a user by id" do
      user = FactoryEx.insert!(Factory.User)

      assert {:ok, ^user} =
               AppConfig.Support.Accounts.find_user(%{
                 id: user.id
               })
    end

    test "returns error if user not found" do
      assert {:error, %ErrorMessage{code: :not_found}} =
               AppConfig.Support.Accounts.find_user(%{
                 id: Enum.random(1..100_000)
               })
    end
  end

  describe "&all_users/1" do
    test "returns all users" do
      users = FactoryEx.insert_many!(6, Factory.User)

      assert {:ok, results} = AppConfig.Support.Accounts.all_users()

      assert Enum.sort(results, & &1.id) === Enum.sort(users, & &1.id)
    end

    test "filters schema by field" do
      users = FactoryEx.insert_many!(10, Factory.User)
      ids = users |> Enum.take(2) |> Enum.map(& &1.id)

      assert {:ok, results} =
               AppConfig.Support.Accounts.all_users(%{
                 id: ids
               })

      result_ids = Enum.map(results, & &1.id)

      assert length(result_ids) === length(ids)
      assert Enum.all?(ids, &(&1 in result_ids))
    end
  end

  describe "&update_user/2" do
    test "updates a user when passed correct params" do
      user = FactoryEx.insert!(Factory.User)
      update_params = FactoryEx.build_params(Factory.User)

      assert {:ok, updated_res} =
               AppConfig.Support.Accounts.update_user(
                 User,
                 user,
                 update_params
               )

      assert update_params === Map.take(updated_res, Map.keys(updated_res))
    end

    test "returns an error when passed invalid params" do
      user = FactoryEx.insert!(Factory.User)
      random_key = user |> Map.drop([:__meta__, :__struct__]) |> Map.keys() |> Enum.random()

      update_params =
        FactoryEx.build(Factory.User, %{
          random_key => if(is_binary(schema_name), do: 1234, else: "1234")
        })

      assert {:error, %Ecto.Changeset{valid?: false}} =
               AppConfig.Support.Accounts.update_user(
                 User,
                 user,
                 new_params
               )
    end
  end

  describe "&delete_user/1" do
    test "removes a user when exists" do
      user = FactoryEx.insert!(Factory.User)

      assert {:ok, ^user} =
               AppConfig.Support.Accounts.delete_user(
                 User,
                 user,
                 new_params
               )
    end
  end
end