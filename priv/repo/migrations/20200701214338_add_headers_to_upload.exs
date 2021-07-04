defmodule Szurupull.Repo.Migrations.AddHeadersToUpload do
  use Ecto.Migration

  def change do
    alter table("uploads") do
      add :headers, {:map, :string}
    end
  end
end
