import Config

config :phoenix, :json_library, Jason

if Mix.env() === :test do
  config :app_gen, AppGen.Support.Repo, pool: Ecto.Adapters.SQL.Sandbox
end
