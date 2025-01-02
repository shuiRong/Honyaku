defmodule Honyaku.Feeds do
  @moduledoc """
  Feeds 上下文的主要 API
  """

  alias Honyaku.Feeds.Services.{FeedService, BuildService, ParseService}

  # 委托主要操作给具体的服务模块
  defdelegate load_translated_feed(url, raw_content, target_lang, source_lang), to: FeedService
  defdelegate build_feed(feed), to: BuildService
  defdelegate parse_feed(feed_type, raw_content), to: ParseService
end
