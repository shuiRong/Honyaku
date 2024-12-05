defmodule Honyaku.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :text, :string
    field :target_language, :string
    field :translated_text, :string
    field :translated_at, :utc_datetime
    belongs_to :article, Honyaku.Article

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:text, :target_language, :translated_text, :translated_at])
    |> validate_required([:text, :target_language, :translated_text, :translated_at])
  end
end
