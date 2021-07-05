defmodule SzurupullWeb.UploadLive.Index do
  use SzurupullWeb, :live_view

  alias Szurupull.Repo
  alias Szurupull.Upload
  alias SzurupullWeb.UploadView

  @impl true
  def render(assigns) do
    UploadView.render("index.html", assigns)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :uploads, list_uploads())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Uploads")
    |> assign(:upload, nil)
  end

  @impl true
  def handle_event("reupload", %{"id" => id}, socket) do
    upload = Repo.get!(Upload, id)
    GenServer.cast(Szurupull.UploaderServer, {:queue, upload})

    {:noreply, assign(socket, :uploads, list_uploads()) |> put_flash(:info, "Reuploading '#{upload.url}''.")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    upload = Repo.get!(Upload, id)
    {:ok, _} = Repo.delete(upload)

    {:noreply, assign(socket, :uploads, list_uploads())}
  end

  defp list_uploads do
    Repo.all(Upload)
  end
end
