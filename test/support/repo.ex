defmodule PhoenixConfig.Support.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_config,
    adapter: Ecto.Adapters.Postgres
end
