defmodule Honyaku.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feeds" do
    field :title, :string
    field :url, :string
    field :subtitle, :string
    has_many :articles, Honyaku.Article

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:url, :title, :subtitle])
    |> validate_required([:url, :title, :subtitle])
  end
end
