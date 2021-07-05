defmodule SzurupullWeb.TestView do
  use SzurupullWeb, :view

  def render_extract_result(result) do
    uploads = Enum.map(result, &render_upload/1) |> Enum.join

    """
    <div class="image-list">
    <div class="panel-list-item">
    <div class="text">Posts: #{Enum.count(result)}</div>
    <div class="images">
    #{uploads}
    </div>
    </div>
    </div>
    """ |> raw()
  end

  def render_upload(upload) do
    tags = Enum.map(upload.tags, &render_tag/1) |> Enum.join

    """
    <div class="gallery-section panel-section panel-section-header">
    <div class="upload-container">
    <div class="left">
    <div class="source">
    <h3>Source</h3>
    <div class="source-url">#{upload.url}</div>
    </div>
    <div class="tags">
    <h3>Tags</h3>
    <div>
    #{tags}
    </div>
    </div>
    </div>
    <div class="image">
    <img src="#{upload.preview_url}"></img>
    </div>
    </div>
    </div>
    """
  end

  def render_tag(tag) do
    """
    <div class="tag #{tag.category}">#{tag.name}</div>
    """
  end
end
