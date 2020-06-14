defmodule Szurupull.UploadView do
  use SzurupullWeb, :view

  def render("index.json", %{uploads: uploads}) do
    Enum.map(uploads, &upload_json/1)
  end

  def render("create.json", %{upload: upload}) do
    upload_json(upload)
  end

  def render("extract.json", %{szuru_uploads: szuru_uploads}) do
    Enum.map(szuru_uploads, &szuru_upload_json/1)
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

  def szuru_upload_json(upload) do
    %{
      source: to_string(upload.source),
      tags: Enum.map(upload.tags, &szuru_tag_json/1),
      uri: to_string(upload.uri),
      safety: Atom.to_string(upload.safety),
      version: upload.version
    }
  end
end
