defmodule PhoenixConfig.Support.Accounts.TeamOrganization do
  @moduledoc "Taken from BlitzPG.AuthAccounts.User"

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias PhoenixConfig.Support.Accounts.{Team, TeamOrganization}

  schema "team_organizations" do
    field :name, :string

    has_many :team, Team
  end

  @required_params [:name]

  def changeset(%TeamOrganization{} = user, attrs \\ %{}) do
    user
      |> cast(attrs, @required_params)
      |> validate_required(@required_params)
  end
end


