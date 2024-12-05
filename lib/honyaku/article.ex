defmodule Honyaku.Article.Content do
  use Ecto.Schema

  embedded_schema do
    field :text, :string
    field :value, :string
  end
end

defmodule Honyaku.Article.Summary do
  use Ecto.Schema

  embedded_schema do
    field :text, :string
    field :value, :string
  end
end

defmodule Honyaku.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :link, :string
    field :title, :string
    field :language, :string
    # 原始文章Feed中记录的发布时间
    field :original_published_at, :utc_datetime

    # 原始文章Feed中记录的更新时间，因为和表中默认的updated_at冲突，所以用original_updated_at
    field :original_updated_at, :utc_datetime
    embeds_one :content, Honyaku.Article.Content
    embeds_one :summary, Honyaku.Article.Summary
    belongs_to :feed, Honyaku.Feed
    has_many :translations, Honyaku.Translation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:link, :title, :language, :original_published_at, :original_updated_at])
    |> cast_embed(:content, with: &content_changeset/2)
    |> cast_embed(:summary, with: &content_changeset/2)
    |> validate_required([:link, :title, :language, :original_published_at, :original_updated_at])
  end

  defp content_changeset(content, attrs) do
    content
    |> cast(attrs, [:text, :value])
    |> validate_required([:text, :value])
  end
end
