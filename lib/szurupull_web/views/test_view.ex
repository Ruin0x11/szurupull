defmodule SzurupullWeb.TestView do
  use SzurupullWeb, :view

  def render_extract_result(result) do
    """
    #{inspect(result)}
    """ |> raw()
  end
end
