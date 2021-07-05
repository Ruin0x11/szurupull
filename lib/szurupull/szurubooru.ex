defmodule Szurupull.Szurubooru do
  require Logger

  defp make_token do
    with username <- Application.get_env(:szurupull, :szurubooru_username),
         password <- Application.get_env(:szurupull, :szurubooru_api_token) do
      Base.encode64("#{username}:#{password}")
    end
  end

  def client do
    [
      {Tesla.Middleware.BaseUrl, Application.get_env(:szurupull, :szurubooru_host)},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Token " <> make_token() }, {"accept", "application/json"}]}
    ]
    |> Tesla.client
  end

  def upload_tag(tag, client) do
    case Tesla.get(client, "/api/tag/#{tag.name}") do
      {:ok, resp} ->
        nonexistent = resp.body["name"] == "TagNotFoundError"
        if nonexistent do
          Logger.info("Creating tag: #{tag.name} (#{tag.category})")
          Tesla.post(client, "/api/tags", %{names: [tag.name], category: Atom.to_string(tag.category)})
        else
          {:ok, nil}
        end
      err -> err
    end
  end

  def serialize_upload(szuru_upload) do
    %{
      source: to_string(szuru_upload.source),
      tags: Enum.map(szuru_upload.tags, fn tag -> tag.name end),
      safety: Atom.to_string szuru_upload.safety
    }
  end

  def download_image(szuru_upload), do: download_image(szuru_upload.source, szuru_upload.uri)

  def download_image(source, uri) do
    with mod <- ToBooru.Scraper.for_uri(source) do
      resp = if function_exported?(mod, :get_image, 1) do
        mod.get_image(uri)
      else
        Tesla.get(Tesla.client([]), to_string(uri), headers: [{"referrer", to_string(source)}])
      end
      case resp do
        {:ok, image} ->
          if image.status == 200 do
            {:ok, image}
          else
            IO.inspect(image)
            {:error, image}
          end
        {:error, e} -> {:error, e}
      end
    end
  end

  defp convert_content_type(resp) do
    case Tesla.get_header(resp, "content-type") do
      t when t in ["application/octet-stream"] -> MIME.from_path(resp.url)
      t -> t
    end
  end

  def make_metadata(szuru_upload, image) do
    md5 = :crypto.hash(:md5, image.body) |> Base.encode16()
    szuru_upload = ToBooru.infer_tags(szuru_upload, md5)
    make_metadata(szuru_upload)
  end

  def make_metadata(szuru_upload) do
    {:ok, serialize_upload(szuru_upload)}
  end

  def make_payload(metadata, image \\ nil) do
    payload = Tesla.Multipart.new()
    |> Tesla.Multipart.add_file_content(Jason.encode!(metadata), "metadata", name: "metadata", headers: [{"content-type", "application/json"}])

    if image do
      content_type = convert_content_type(image)
      payload
      |> Tesla.Multipart.add_file_content(image.body, "content", name: "content", headers: [{"content-type", content_type}])
    else
      payload
    end
  end
end
