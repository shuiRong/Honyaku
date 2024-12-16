defmodule Honyaku.Repo.Migrations.AddBelongsToInTranslation do
  use Ecto.Migration

  def change do
    alter table(:translations) do
      add :feed_id, references(:feeds, on_delete: :delete_all)
    end

    create index(:translations, [:feed_id])
  end
end
