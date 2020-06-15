import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :szurupull, Szurupull.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :szurupull, SzurupullWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("VIRTUAL_PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [host: System.get_env("LETSENCRYPT_HOST")],
  secret_key_base: secret_key_base

config :szurupull, SzurupullWeb.Endpoint, server: true
