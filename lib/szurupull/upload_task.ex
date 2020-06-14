defmodule Szurupull.UploadTask do
  require Logger
  use Task

  def start_link(upload) do
    Task.start_link(__MODULE__, :run, [upload])
  end

  defp make_token do
    with username <- Application.get_env(:szurupull, :szurubooru_username),
         password <- Application.get_env(:szurupull, :szurubooru_api_token) do
      Base.encode64("#{username}:#{password}")
    end
  end

  defp client do
    [
      {Tesla.Middleware.BaseUrl, Application.get_env(:szurupull, :szurubooru_host)},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Token " <> make_token() }, {"accept", "application/json"}]}
    ]
    |> Tesla.client
  end

  defp upload_tag(tag, client) do
    with {:ok, resp} <- Tesla.get(client, "/api/tag/#{tag.name}"),
      nonexistent <- resp.body["name"] == "TagNotFoundError" do
      if nonexistent do
        Logger.info("Creating tag: #{tag.name} (#{tag.category})")
        Tesla.post(client, "/api/tags", %{names: [tag.name], category: Atom.to_string(tag.category)})
      else
        {:ok, nil}
      end
    end
  end

  defp serialize_upload(szuru_upload) do
    %{
      source: to_string(szuru_upload.source),
      tags: Enum.map(szuru_upload.tags, fn tag -> tag.name end),
      safety: Atom.to_string szuru_upload.safety
    }
  end

  defp make_payload(szuru_upload) do
    Logger.info("Getting image: #{to_string(szuru_upload.uri)}")
    with client <- Tesla.client([]),
         metadata <- serialize_upload(szuru_upload),
         {:ok, image} <- Tesla.get(client, to_string(szuru_upload.uri), headers: [{"referrer", to_string(szuru_upload.source)}]),
           content_type <- Tesla.get_header(image, "content-type") do
      Tesla.Multipart.new()
      |> Tesla.Multipart.add_file_content(Jason.encode!(metadata), "metadata", name: "metadata", headers: [{"content-type", "application/json"}])
      |> Tesla.Multipart.add_file_content(image.body, "content", name: "content", headers: [{"content-type", content_type}])
    end
  end

  defp upload(client, szuru_upload) do
    Logger.info("Starting upload: #{szuru_upload.uri}")
    Enum.map(szuru_upload.tags, fn tag -> upload_tag(tag, client) end)
    with payload <- make_payload(szuru_upload) do
      Logger.info("Uploading post: #{to_string(szuru_upload.uri)}")
      Tesla.post(client, "/api/posts", payload)
    end
  end

  def run(szuru_upload) do
    client()
    |> upload(szuru_upload)
    |> IO.inspect
  end
end
