defmodule Honyaku.Repo.Migrations.RemoveTranslatedAtFieldInTranslation do
  use Ecto.Migration

  def change do
    alter table(:translations) do
      remove :translated_at
    end
  end
end
