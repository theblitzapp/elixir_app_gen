import PhoenixConfig, only: [crud_from_schema: 2]

[
  crud_from_schema(PhoenixConfig.Support.Accounts, PhoenixConfig.Support.Accounts.User)
]
