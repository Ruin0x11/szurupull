defmodule SzurupullWeb.UploadLive.Show do
  use SzurupullWeb, :live_view

  alias Szurupull.Repo
  alias Szurupull.Upload
  alias SzurupullWeb.UploadView

  @impl true
  def render(assigns) do
    UploadView.render("show.html", assigns)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
      assign(socket,
        page_title: page_title(socket.assigns.live_action),
        upload: Repo.get!(Upload, id))}
  end

  defp page_title(:show), do: "Show User"
end
