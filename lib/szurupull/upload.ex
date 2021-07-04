defmodule Szurupull.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "uploads" do
    field :url, :string
    field :extra_tags, {:array, :string}, default: []
    field :pools, {:array, :string}, default: []
    field :status, StatusEnum, default: :new
    field :error, :string
    field :headers, {:map, :string}, default: %{}

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:url, :extra_tags, :pools, :status, :error, :headers])
    |> validate_required([:url, :status, :extra_tags, :pools])
    |> unique_constraint(:url)
  end
end
