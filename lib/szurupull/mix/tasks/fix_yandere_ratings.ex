defmodule Mix.Tasks.FixYandereRatings do
  require Logger
  use Mix.Task
  alias Szurupull.Szurubooru

  defp get_posts(client, offset, limit, query) do
    client
    |> Tesla.get("/api/posts", query: [{:offset, offset}, {:limit, limit}, {:query, query}])
  end

  @limit 100

  @shortdoc "Fixes yande.re ratings"
  def run(args) do
    {args, _, _} = OptionParser.parse(args, strict: [query: :string])
    Mix.Task.run("app.start")

    client = Szurubooru.client()
    stream = Stream.unfold(0, fn offset ->
      {:ok, result} = get_posts(client, offset, @limit, Keyword.get(args, :query) || "source:yande.re")
      Enum.each(result.body["results"], fn post ->
        upload = ToBooru.extract_uploads(post["source"]) |> Enum.at(0)
        if upload do
          result = with {:ok, metadata} <- Szurubooru.make_metadata(upload),
          metadata <- Map.put(metadata, :version, post["version"]),
          {:ok, env} <- Tesla.put(client, "/api/post/#{post["id"]}", Szurubooru.make_payload(metadata)) do
            if env.status == 200 do
              {:ok, env.body}
            else
              {:error, env.body}
            end
          end

          case result do
            {:ok, _} -> Logger.warn("Updated upload with md5 #{post["checksumMD5"]}: #{upload.safety}")
            {:error, error} -> Logger.error("Failed to update post: #{inspect(error)}")
          end
        else
          Logger.error("Can't find upload with url #{post["source"]}")
        end
      end)

      if result.body["total"] <= offset do
        nil
      else
        {:ok, offset + @limit}
      end
    end)

    Stream.run(stream)
  end
end
