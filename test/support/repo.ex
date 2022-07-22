defmodule AppGen.Support.Repo do
  use Ecto.Repo,
    otp_app: :app_gen,
    adapter: Ecto.Adapters.Postgres
end
