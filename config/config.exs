# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :concept,
  ecto_repos: [Concept.Repo]

# Configures the endpoint
config :concept, ConceptWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OhUK/5qO/uPoK31POPuju86KDAczv2NcdBoIfil4XMJL+kBJ2v72OWEeRRAWMX5V",
  render_errors: [view: ConceptWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Concept.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
