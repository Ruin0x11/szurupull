use Mix.Config

config :extwitter, :oauth, [
   consumer_key: "key",
   consumer_secret: "secret",
   access_token: "key",
   access_token_secret: "secret"
]
config :to_booru, pixiv_username: "username"
config :to_booru, pixiv_password: "password"

config :to_booru, danbooru2_tag_lookup_host: "https://danbooru.donmai.us"

config :szurupull, szurubooru_host: "https://example.com"
config :szurupull, szurubooru_username: "username"
config :szurupull, szurubooru_api_token: "password"

config :szurupull, :basic_auth, username: "szurupull_username", password: "szurupull_password"
