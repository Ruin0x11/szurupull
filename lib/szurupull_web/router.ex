defmodule SzurupullWeb.Router do
  use SzurupullWeb, :router
  import Phoenix.LiveView.Router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {SzurupullWeb.LayoutView, :root}
  end

  pipeline :protected do
    plug :basic_auth, Application.compile_env(:szurupull, :basic_auth)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SzurupullWeb do
    pipe_through [:protected, :browser]

    get "/", PageController, :index
    live "/test", TestLive.Show, :show, as: :test_live
  end

  scope "/api", Szurupull do
    pipe_through [:protected, :api]

    resources "/uploads", UploadController, only: [:index, :create]
    get "/uploads/extract", UploadController, :extract, as: :extract
    get "/uploads/check", UploadController, :check, as: :check
  end

  # Other scopes may use custom stacks.
  # scope "/api", SzurupullWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SzurupullWeb.Telemetry
    end
  end
end
