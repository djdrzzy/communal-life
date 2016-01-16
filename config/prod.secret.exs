use Mix.Config

config :gol, Gol.Endpoint,
  secret_key_base: System.get_env("GOL_ENDPOINT_SECRET_KEY_BASE")
