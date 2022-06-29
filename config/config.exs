import Config

config :phoenix, :json_library, Jason

if Mix.env() === :test do
  config :phoenix_config, PhoenixConfig.Support.Repo, pool: Ecto.Adapters.SQL.Sandbox
end
