defmodule SzurupullWeb.TestLive.Show do
  use Phoenix.LiveView, layout: {SzurupullWeb.LayoutView, "live.html"}
  alias SzurupullWeb.TestView
  alias SzurupullWeb.Router.Helpers, as: Routes
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    pages = Application.get_env(:szurupull, :test_pages)

    monitors = Enum.map(pages, fn page ->
      %Task{ref: ref} = Task.Supervisor.async(Szurupull.TaskSupervisor, SzurupullWeb.TestLive.TestTask, :test, [page, socket])
      {ref, %{page: page, state: :loading, result: nil}}
    end)
    |> Enum.into(%{})

    {:ok, assign(socket, monitors: monitors)}
  end

  @impl true
  def render(assigns) do
    TestView.render("show.html", assigns)
  end

  @impl true
  def handle_info({ref, {:success, result}}, socket) do
    update(ref, :success, result, socket)
 end

  @impl true
  def handle_info({ref, {:failure, result}}, socket) do
    update(ref, :failure, result, socket)
 end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{assigns: %{monitors: monitors}} = socket) do
    case Map.get(monitors, ref) do
      %{state: :loading} -> update(ref, :failure, :DOWN, socket)
      _ -> {:noreply, socket}
    end
  end

  defp update(ref, state, result, %{assigns: %{monitors: monitors}} = socket) do
    info = Map.get(monitors, ref)
    monitors = Map.put(monitors, ref, %{info | state: state, result: result})
    Logger.warn("Task ended: #{inspect(state)} #{inspect(result)}")
    {:noreply, assign(socket, monitors: monitors)}
  end

  @impl true
  def handle_info(message, socket) do
    Logger.warn("Unhandled message: #{inspect(message)} #{inspect(socket)}")
    {:noreply, socket}
  end
end

defmodule SzurupullWeb.TestLive.TestTask do
  alias SzurupullWeb.Router.Helpers, as: Routes

  def test(url, socket) do
    result = Tesla.client([
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BaseUrl, SzurupullWeb.Endpoint.url()},
      {Tesla.Middleware.BasicAuth, Application.get_env(:szurupull, :basic_auth)}
    ])
    |> Tesla.get(Routes.extract_path(socket, :extract), query: [{:url, url}])

    case result do
      {:ok, env} -> if env.status == 200 do
        {:success, env.body}
      else
        {:failure, env}
      end
      {:err, error} -> {:failure, error}
    end
  end
end
