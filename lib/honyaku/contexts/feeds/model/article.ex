defmodule Honyaku.Feeds.Article.Content do
  use Ecto.Schema

  embedded_schema do
    field :type, :string
    field :value, :string
  end
end

defmodule Honyaku.Feeds.Article.Summary do
  use Ecto.Schema

  embedded_schema do
    field :type, :string
    field :value, :string
  end
end

defmodule Honyaku.Feeds.Article do
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

    # 文章内容
    # on_replace: :update 表示当文章内容被更新时，连带着直接更新 content schema 的内容
    embeds_one :content, Honyaku.Feeds.Article.Content, on_replace: :update

    # 文章摘要
    # on_replace: :update 表示当文章摘要被更新时，连带着直接更新 summary schema 的内容
    embeds_one :summary, Honyaku.Feeds.Article.Summary, on_replace: :update

    belongs_to :feed, Honyaku.Feeds.Feed
    has_many :translations, Honyaku.Feeds.Translation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [
      :link,
      :title,
      :language,
      :original_published_at,
      :original_updated_at,
      :feed_id
    ])
    |> cast_embed(:content, with: &content_changeset/2)
    |> cast_embed(:summary, with: &summary_changeset/2)
    |> validate_required([:link, :title, :original_published_at, :original_updated_at, :feed_id])
    |> unique_constraint([:link, :feed_id])
    |> assoc_constraint(:feed)
  end

  defp content_changeset(content, attrs) do
    content
    |> cast(attrs, [:type, :value])
    |> validate_required([:type, :value])
  end

  defp summary_changeset(summary, attrs) do
    summary
    |> cast(attrs, [:type, :value])
  end
end
