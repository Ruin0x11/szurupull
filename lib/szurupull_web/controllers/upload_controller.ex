defmodule Szurupull.UploadController do
  use SzurupullWeb, :controller

  alias Szurupull.{Repo, Upload}

  def index(conn, _params) do
    uploads = Repo.all(Upload)
    render conn, "index.json", uploads: uploads
  end

  def create(conn, %{"url" => url}) do
    case Repo.insert(Upload.changeset(%Upload{url: url}, %{})) do
      {:ok, upload} ->
        GenServer.cast(Szurupull.UploaderServer, {:queue, upload})
        render(conn, "create.json", upload: upload)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> render(SzurupullWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def extract(conn, %{"url" => url}) do
    szuru_uploads = ToBooru.extract_uploads(url)
    render conn, "extract.json", szuru_uploads: szuru_uploads
  end
end
