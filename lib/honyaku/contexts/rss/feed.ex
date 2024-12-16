defmodule Honyaku.RSS.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feeds" do
    field :url, :string
    field :source_lang, :string
    field :target_lang, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:url, :source_lang, :target_lang])
    |> validate_required([:url, :source_lang, :target_lang])
  end
end
