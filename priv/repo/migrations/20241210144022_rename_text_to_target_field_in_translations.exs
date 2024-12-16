defmodule Honyaku.Repo.Migrations.RenameTextToTargetFieldInTranslations do
  use Ecto.Migration

  def change do
    rename table(:translations), :text, to: :target_field
  end
end
