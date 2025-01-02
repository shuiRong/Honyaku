defmodule Honyaku.Feeds.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Honyaku.Feeds.{Article, Feed}

  # 记录翻译结果
  schema "translations" do
    # 记录原文所在表的字段名称，比如：title、subtitle、content、summary
    # 用来反查询原文
    # 因为原文的表中可能同时存在多个字段都有对应的翻译数据
    field :target_field, :string
    field :target_language, :string
    field :translated_text, :string
    belongs_to :article, Article
    belongs_to :feed, Feed

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:target_field, :target_language, :translated_text])
    |> validate_required([:target_field, :target_language, :translated_text])
    |> unique_constraint([:target_field, :target_language])
    |> assoc_constraint(:article)
    |> assoc_constraint(:feed)
  end
end
