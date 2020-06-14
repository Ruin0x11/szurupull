defmodule SzurupullWeb.PageController do
  use SzurupullWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
