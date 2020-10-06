defmodule RedditRss.Reddit do
  alias RedditRss.Helpers

  @spec id(map) :: binary
  def id(%{"id" => val}), do: val

  @spec title(map) :: binary
  def title(%{"title" => val}), do: val

  @spec pubDate(map) :: binary
  def pubDate(%{"created" => val}) do
    val
    |> floor()
    |> Timex.from_unix()
    |> Helpers.formatDate()
  end

  @spec link(map) :: binary
  def link(%{"url" => val}), do: val

  @spec is_media(map) :: boolean
  def is_media(%{"media" => nil, "secure_media" => nil, "media_embed" => nil}), do: false

  def is_media(%{"media" => nil, "secure_media" => nil, "media_embed" => val})
      when map_size(val) == 0,
      do: false

  def is_media(%{"media" => v}) when not is_nil(v), do: true
  def is_media(%{"secure_media" => v}) when not is_nil(v), do: true
  def is_media(%{"media_embed" => v}) when not is_nil(v), do: true

  @spec media(map) :: nil | binary
  def media(%{"media" => nil, "secure_media" => nil, "media_embed" => nil}), do: nil

  def media(%{"secure_media" => %{"oembed" => %{"html" => val}}}) do
    val
    |> HtmlEntities.decode()
    |> (&Regex.replace(~r/(&.+;)/, &1, "")).()
  end

  def media(%{"media" => %{"oembed" => %{"html" => val}}}) do
    val
    |> HtmlEntities.decode()
    |> (&Regex.replace(~r/(&.+;)/, &1, "")).()
  end

  def media(%{"media_embed" => %{"content" => val}}) do
    val
    |> HtmlEntities.decode()
    |> (&Regex.replace(~r/(&.+;)/, &1, "")).()
  end
end
