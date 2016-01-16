# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :gol, Gol.Endpoint,
  url: [host: "localhost"],
  code_reloader: false,
  root: Path.dirname(__DIR__),
  secret_key_base: System.get_env("GOL_ENDPOINT_SECRET_KEY_BASE"),
  render_errors: [accepts: ~w(html json)],
	server: true,
  pubsub: [name: Gol.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false
