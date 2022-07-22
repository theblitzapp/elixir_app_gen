defmodule AppGen.Support.Factory.User do
  @behaviour FactoryEx

  def schema, do: AppGen.Support.Accounts.User

  def repo, do: AppGen.Support.Repo

  def build(params \\ %{}) do
    Map.merge(%{
      name: Faker.Name.name(),
      email: Faker.Internet.email(),
      gender: Enum.random(["MALE", "FEMALE"]),
      birthday: Faker.Date.date_of_birth(17..88),
      location: Faker.Address.country()
    }, params)
  end
end
