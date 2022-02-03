import PhoenixConfig, only: [crud_from_schema: 1, remove_relations: 2]

alias PhoenixConfig.Support.Accounts

[
  crud_from_schema(Accounts.User),
  # crud_from_schema(Accounts.TeamOrganization),
  remove_relations(Accounts.Role, [:users]),
  remove_relations(Accounts.Team, :users)
]
