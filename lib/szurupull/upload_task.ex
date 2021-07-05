defmodule Szurupull.UploadTask do
  require Logger
  use Task

  alias Szurupull.Szurubooru

  defp infer_tags(szuru_upload, image, client) do
    md5 = :crypto.hash(:md5, image.body) |> Base.encode16()
    szuru_upload = ToBooru.infer_tags(szuru_upload, md5)
    tag_results = Enum.map(szuru_upload.tags, fn tag -> Szurubooru.upload_tag(tag, client) end)
    case Enum.find(tag_results, fn {r, _} -> r == :error end) do
      nil -> {:ok, szuru_upload}
      err -> err
    end
  end

  defp update_post(client, post, metadata, image) do
    with metadata <- Map.put(metadata, :version, post["version"]),
         {:ok, env} <- Tesla.put(client, "/api/post/#{post["id"]}", Szurubooru.make_payload(metadata, image)) do
      if env.status == 200 do
        {:ok, env}
      else
        {:err, env.body["description"]}
      end
    end
  end

  defp upload(client, szuru_upload) do
    Logger.info("Starting upload: #{szuru_upload.uri}")
    with {:ok, image} <- Szurubooru.download_image(szuru_upload),
         {:ok, szuru_upload} <- infer_tags(szuru_upload, image, client),
         {:ok, metadata} <- Szurubooru.make_metadata(szuru_upload, image) do
      Logger.info("Uploading post: #{to_string(szuru_upload.uri)}")
      with {:ok, env} <- Tesla.post(client, "/api/posts", Szurubooru.make_payload(metadata, image)) do
        if env.status == 200 do
          {:ok, env}
        else
          if env.body["name"] == "PostAlreadyUploadedError" do
            other_post_id = env.body["otherPostId"]
            with {:ok, existing_post} <- Tesla.get(client, "/api/post/#{other_post_id}") do
              if existing_post.status == 200 do
                Logger.info("Updating post with new data: #{to_string(szuru_upload.uri)}")
                update_post(client, existing_post.body, metadata, image)
              else
                {:err, existing_post.body["description"]}
              end
            end
          else
            {:err, env.body["description"]}
          end
        end
      end
    end
  end

  def run(szuru_upload) do
    Szurupull.Szurubooru.client()
    |> upload(szuru_upload)
  end
end
