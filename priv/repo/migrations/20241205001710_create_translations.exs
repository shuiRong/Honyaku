defmodule Honyaku.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :text, :string
      add :target_language, :string
      add :translated_text, :text
      add :translated_at, :utc_datetime
      add :article_id, references(:articles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:translations, [:article_id])
  end
end
