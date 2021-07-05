# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :szurupull,
  ecto_repos: [Szurupull.Repo],
  test_urls: [
    "https://www.pixiv.net/artworks/89023335",
    "https://twitter.com/taktwi/status/1411323853263937537",
    "https://danbooru.donmai.us/posts/472445",
    "https://yande.re/post/show/760737",
    "https://gelbooru.com/index.php?page=post&s=view&id=6235985",
    "https://upload.wikimedia.org/wikipedia/commons/e/e1/Bruck_L1400826.jpg?download"
  ]

# List of conversions from Pixiv to szurubooru tags, in case those tags aren't
# available in the Danbooru 2 instance.
config :to_booru, :tag_lookup_overrides, %{
  "メイキング" => [%{name: "making_of", category: :tutorial}],
  "講座"       => [%{name: "drawing_course", category: :tutorial}],
  "目の描き方" => [%{name: "how_to", category: :tutorial}, %{name: "how_to_draw_eyes", category: :tutorial}],
  "構図" =>       [%{name: "composition", category: :tutorial}]
}

# Configures the endpoint
config :szurupull, SzurupullWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Sk+ZD6yRrjhwu4FljVB4dRhbblvCrjHSecvmLe0X64iJSoC+rVImmOZ0I5YkT0z+",
  render_errors: [view: SzurupullWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Szurupull.PubSub,
  live_view: [signing_salt: "zISDRNiN"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :file, :line]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, adapter: Tesla.Adapter.Hackney

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

import_config "secret.exs"
