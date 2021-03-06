defmodule SzurupullWeb.UploadController do
  use SzurupullWeb, :controller

  require Ecto.Query
  alias Szurupull.{Repo, Upload}

  def index(conn, _params) do
    uploads = Upload |> Ecto.Query.order_by([u], desc: u.updated_at) |> Repo.all
    render conn, "index.json", uploads: uploads
  end

  def create(conn, %{"url" => url}) do
    case Repo.get_by(Upload, url: url) do
      nil -> case Repo.insert(Upload.changeset(%Upload{url: url}, %{})) do
               {:ok, upload} ->
                 GenServer.cast(Szurupull.UploaderServer, {:queue, upload})
                 render(conn, "create.json", upload: upload)
               {:error, %Ecto.Changeset{} = changeset} ->
                 conn
                 |> put_status(400)
                 |> render(SzurupullWeb.ChangesetView, "error.json", changeset: changeset)
               {:error, _err} ->
                 conn
                 |> render_error(400)
             end
      upload ->
        GenServer.cast(Szurupull.UploaderServer, {:queue, upload})
        render(conn, "create.json", upload: upload)
    end
  end

  def extract(conn, %{"url" => url}) do
    szuru_uploads = ToBooru.extract_uploads(url)
    render conn, "extract.json", szuru_uploads: szuru_uploads
  end

  def check(conn, %{"url" => url}) do
    scraper = case ToBooru.Scraper.for_uri(url) do
                nil -> nil
                mod -> mod.name
              end
    render conn, "check.json", scraper: scraper
  end
end
