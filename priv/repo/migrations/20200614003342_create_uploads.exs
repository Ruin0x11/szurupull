defmodule Szurupull.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    StatusEnum.create_type
    create table(:uploads) do
      add :url, :text
      add :extra_tags, {:array, :string}
      add :pools, {:array, :string}
      add :status, StatusEnum.type()
      add :error, :text

      timestamps()
    end

    create unique_index(:uploads, [:url])
  end
end
