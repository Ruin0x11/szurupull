defmodule Mix.Tasks.FixTwitter do
  require Logger
  use Mix.Task
  alias Szurupull.Szurubooru

  defp get_posts(client, offset, limit) do
    client
    |> Tesla.get("/api/posts", query: [{:offset, offset}, {:limit, limit}, {:query, "source:twitter.com"}])
  end

  @limit 100

  @shortdoc "Updates Twitter images to highest quality"
  def run(_) do
    Mix.Task.run("app.start")

    client = Szurubooru.client()
    stream = Stream.unfold({0, %{}}, fn {offset, cache} ->
      {:ok, result} = get_posts(client, offset, @limit)
      cache = Enum.reduce(result.body["results"], cache, fn post, cache ->
        source = post["source"]
        {large_md5s, cache} =
          case Map.get(cache, source) do
            nil ->
              uploads = ToBooru.extract_uploads(source)
              large_md5s = Enum.map(uploads, fn upload ->
                uri = %{upload.uri | path: String.replace_suffix(upload.uri.path, ":orig", "") }
                {:ok, image} = Szurubooru.download_image(upload.source, uri)
                {:crypto.hash(:md5, image.body) |> Base.encode16() |> String.downcase, upload}
              end)
              |> Enum.into(%{})
              {large_md5s, Map.put(cache, source, large_md5s)}
            x -> {x, cache}
          end

        upload = Map.get(large_md5s, post["checksumMD5"] |> String.downcase)
        if upload do
          result = with {:ok, image} <- Szurubooru.download_image(upload),
          {:ok, metadata} <- Szurubooru.make_metadata(upload, image),
          metadata <- Map.put(metadata, :version, post["version"]),
          {:ok, env} <- Tesla.put(client, "/api/post/#{post["id"]}", Szurubooru.make_payload(metadata, image)) do
            if env.status == 200 do
              {:ok, env.body}
            else
              {:error, env.body}
            end
          end

          case result do
            {:ok, _} -> Logger.warn("Updated upload with md5 #{post["checksumMD5"]}")
            {:error, error} -> Logger.error("Failed to update post: #{inspect(error)}")
          end
        else
          Logger.error("Can't find upload with md5 #{post["checksumMD5"]}")
        end

        cache
      end)

      if result.body["total"] <= offset do
        nil
      else
        {:ok, {offset + @limit, cache}}
      end
    end)

    Stream.run(stream)
  end
end
