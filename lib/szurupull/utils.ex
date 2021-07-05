defmodule Szurupull.Utils do
  alias Szurupull.{Repo, Upload}

  def upload(url) do
    case Repo.get_by(Upload, url: url) do
      nil -> case Repo.insert(Upload.changeset(%Upload{url: url}, %{})) do
               {:ok, upload} ->
                 GenServer.cast(Szurupull.UploaderServer, {:queue, upload})
                 {:ok, upload}
               x -> x
             end
      upload ->
        GenServer.cast(Szurupull.UploaderServer, {:queue, upload})
        {:ok, upload}
    end
  end
end
