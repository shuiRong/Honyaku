defmodule Honyaku.Feeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feeds" do
    field :title, :string
    field :url, :string
    field :subtitle, :string
    field :original_updated_at, :utc_datetime
    has_many :articles, Honyaku.Feeds.Article
    has_many :translations, Honyaku.Feeds.Translation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:url, :title, :subtitle, :original_updated_at])
    |> validate_required([:url, :title, :original_updated_at])
    |> unique_constraint(:url)
  end
end
