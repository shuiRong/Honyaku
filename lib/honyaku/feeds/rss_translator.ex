defmodule Honyaku.Feeds.RSSTranslator do
  @moduledoc """
  处理 RSS 订阅源的获取、解析和翻译
  """
  require Logger

  def translate_feed(url, _source_lang, _target_lang) do
    with {:ok, raw_content} <- fetch_feed(url),
         {:ok, feed_type} <- determine_feed_type(raw_content),
         {:ok, parsed_feed} <- parse_feed(raw_content, feed_type) do
      # 根据需要进行翻译处理
      {:ok, parsed_feed, feed_type}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_feed(url) do
    req =
      Req.new(
        headers: [{"user-agent", "RSS Translator Bot"}],
        max_redirects: 5
      )

    case Req.get(req, url: url) do
      {:ok, %{status: 200, body: body}} ->
        Logger.debug("获取成功: #{inspect(body)}")
        {:ok, body}

      {:ok, response} ->
        {:error, "获取失败: #{response.status}"}

      {:error, error} ->
        {:error, "请求错误: #{inspect(error)}"}
    end
  end

  defp determine_feed_type(raw_content) do
    trimmed_content = String.trim_leading(raw_content)

    cond do
      String.starts_with?(trimmed_content, "<?xml") ->
        case String.contains?(trimmed_content, "<rss") do
          true ->
            {:ok, :rss}

          false ->
            case String.contains?(trimmed_content, "<feed") do
              true -> {:ok, :atom}
              false -> {:error, "未知的 feed 类型"}
            end
        end

      String.starts_with?(trimmed_content, "<rss") ->
        {:ok, :rss}

      String.starts_with?(trimmed_content, "<feed") ->
        {:ok, :atom}

      true ->
        {:error, "无法确定 feed 类型"}
    end
  end

  defp parse_feed(raw_content, :rss) do
    case FastRSS.parse_rss(raw_content) do
      {:ok, parsed_feed} -> {:ok, parsed_feed}
      error -> error
    end
  end

  defp parse_feed(raw_content, :atom) do
    case FastRSS.parse_atom(raw_content) do
      {:ok, parsed_feed} -> {:ok, parsed_feed}
      error -> error
    end
  end
end
