defmodule Szurupull.UploaderServer do
  require Logger
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(_) do
    {:ok, {%{}}}
  end

  @impl true
  def handle_cast({:queue, upload}, {monitors}) do
    Logger.info("Queuing: #{upload.id} #{upload.url}")

    Szurupull.Upload.changeset(upload, %{status: :pending})
    |> Szurupull.Repo.update!

    try do
      with uploads <- upload.url |> ToBooru.extract_uploads do
        if Enum.empty?(uploads) do
          Szurupull.Upload.changeset(upload, %{status: :failed, error: "No uploads found for link."})
          |> Szurupull.Repo.update!
          {:noreply, {monitors}}
        else
          uploads
          |> Enum.map(fn szuru_upload ->
            {:ok, task} = Szurupull.UploadTask.start_link(szuru_upload)
            {Process.monitor(task), {upload, szuru_upload}}
          end)
          |> (&({:noreply, {Enum.into(&1, monitors)}})).()
        end
      end
    rescue
      e ->
        mes = Exception.format(:error, e, __STACKTRACE__)
        Logger.error(mes)
        Szurupull.Upload.changeset(upload, %{status: :failed, error: mes})
        |> Szurupull.Repo.update!
      {:noreply, {monitors}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {monitors}) do
    {{upload, _}, monitors} = Map.pop(monitors, ref)
    Logger.info("Finished: #{upload.id} #{upload.url}")
    Szurupull.Upload.changeset(upload, %{status: :succeeded})
    |> Szurupull.Repo.update!
    {:noreply, {monitors}}
  end

  @impl true
  def handle_info(_msg, {monitors}) do
    {:noreply, {monitors}}
  end
end
