defmodule AppConfig.Support.Repo do
  use Ecto.Repo,
    otp_app: :app_config,
    adapter: Ecto.Adapters.Postgres
end
