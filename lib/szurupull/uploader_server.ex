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

    Szurupull.Upload.changeset(upload, %{status: :pending, error: ""})
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
            %Task{ref: ref} = Task.Supervisor.async(Szurupull.TaskSupervisor, Szurupull.UploadTask, :run, [szuru_upload])
            {ref, {upload, szuru_upload}}
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
  def handle_info({ref, {:ok, _result}}, {monitors}) do
    {upload, _} = Map.get(monitors, ref)
    Logger.info("Upload succeded: #{upload.id} #{upload.url}")
    update(monitors, ref, :succeeded)
  end

  @impl true
  def handle_info({ref, {:error, result}}, {monitors}) do
    {upload, _} = Map.get(monitors, ref)
    Logger.error("Upload failed: #{upload.id} #{upload.url} - #{inspect(result)}")
    update(monitors, ref, :failed, inspect(result))
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {monitors} = state) do
    if Map.has_key?(monitors, ref) do
      {upload, _} = Map.get(monitors, ref)
      Logger.error("Upload errored: #{upload.id} #{upload.url}")
      update(monitors, ref, :failed, "(error)")
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp update(monitors, ref, status, error \\ "") do
    {{upload, _}, monitors} = Map.pop(monitors, ref)
    Szurupull.Upload.changeset(upload, %{error: error}) |> Szurupull.Repo.update!
    Szurupull.Upload.changeset(upload, %{status: status}) |> Szurupull.Repo.update!
    {:noreply, {monitors}}
  end
end
