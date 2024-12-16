defmodule Honyaku.Utils.DateTimeUtils do
  @moduledoc """
  集中处理时间
  """

  require Logger

  @doc """
  将来自外部的时间字符串解析为 DateTime.to_iso8601 支持的格式，也就是有效的Elixir时间
  因为存在各种格式，所以都得处理
  """
  def parse_datetime(datetime) do
    # 按优先级尝试不同的格式
    # 注意cond会将任何不是nil或false的值认为真
    cond do
      # Tue, 05 Mar 2013 23:25:19 EST
      result = try_parse_datetime(datetime, "{RFC1123}") ->
        result

      # Tue, 06 Mar 2013 01:25:19 Z
      result = try_parse_datetime(datetime, "{RFC1123z}") ->
        result

      # Mon, 05 Jun 14 23:20:59 UTC
      result = try_parse_datetime(datetime, "{RFC822}") ->
        result

      # Mon, 05 Jun 14 23:20:59 +00:00
      result = try_parse_datetime(datetime, "{RFC822z}") ->
        result

      # 2013-03-05T23:25:19+02:00
      result = try_parse_datetime(datetime, "{RFC3339}") ->
        result

      # 2013-03-05T23:25:19Z
      result = try_parse_datetime(datetime, "{RFC3339z}") ->
        result

      # 20090305232519
      result = try_parse_datetime(datetime, "{ASN1:GeneralizedTime}") ->
        result

      # 20090305232519.456Z
      result = try_parse_datetime(datetime, "{ASN1:GeneralizedTime:Z}") ->
        result

      # 20090305232519.000-0700
      result = try_parse_datetime(datetime, "{ASN1:GeneralizedTime:TZ}") ->
        result

      # 130305232519Z
      result = try_parse_datetime(datetime, "{ASN1:UTCtime}") ->
        result

      # 2014-08-14T12:34:33+00:00
      result = try_parse_datetime(datetime, "{ISO:Extended}") ->
        result

      # 2014-08-14T12:34:33Z
      result = try_parse_datetime(datetime, "{ISO:Extended:Z}") ->
        result

      # 20140814T123433-0000
      result = try_parse_datetime(datetime, "{ISO:Basic}") ->
        result

      # 20140814T123433Z
      result = try_parse_datetime(datetime, "{ISO:Basic:Z}") ->
        result

      # 2007-08-13
      result = try_parse_datetime(datetime, "{ISOdate}") ->
        result

      true ->
        {:error, "无法解析时间格式: #{datetime}"}
    end
  end

  # 尝试解析时间，只要不成功，都明确返回 false，来让 cond 继续尝试其他格式
  defp try_parse_datetime(datetime, format) do
    case Timex.parse(datetime, format) do
      {:ok, result} -> {:ok, result}
      _ -> false
    end
  end
end
