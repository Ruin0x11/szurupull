defmodule SzurupullWeb.UploadView do
  use SzurupullWeb, :view
  require Ecto.Query

  def render("index.json", %{uploads: uploads}) do
    Enum.map(uploads, &upload_json/1)
  end

  def render("create.json", %{upload: upload}) do
    upload_json(upload)
  end

  def render("extract.json", %{szuru_uploads: szuru_uploads}) do
    Enum.map(szuru_uploads, &szuru_upload_json/1)
  end

  def render("check.json", %{scraper: scraper}) do
    %{ scraper: scraper }
  end

  def upload_json(upload) do
    %{
      id: upload.id,
      url: upload.url,
      status: upload.status,
      extra_tags: upload.extra_tags,
      pools: upload.pools,
      error: upload.error,
      inserted_at: upload.inserted_at,
      updated_at: upload.updated_at
    }
  end

  def szuru_tag_json(tag) do
    %{
      name: tag.name,
      category: Atom.to_string(tag.category)
    }
  end

  def already_uploaded?(upload) do
    with url <- to_string(upload.source) do
      Szurupull.Upload
      |> Ecto.Query.where([u], u.url == ^url)
      |> Szurupull.Repo.one
      |> (&(!is_nil &1)).()
    end
  end

  def szuru_upload_json(upload) do
    %{
      already_uploaded: already_uploaded?(upload),
      source: to_string(upload.source),
      tags: Enum.map(upload.tags, &szuru_tag_json/1),
      url: to_string(upload.uri),
      preview_url: to_string(upload.preview_uri),
      safety: Atom.to_string(upload.safety),
      version: upload.version
    }
  end
end
