defmodule RedditRss.Rss do
  alias RedditRss.Reddit
  alias RedditRss.Helpers
  alias Plug.Conn

  @spec handle_reddit_resp(
          {:error, %{position: any}} | {:ok, map},
          any,
          atom | %{request_path: any}
        ) :: Plug.Conn.t()
  def handle_reddit_resp({:ok, %{"data" => %{"children" => children}}}, client, conn) do
    now =
      Timex.now()
      |> Helpers.formatDate()

    children
    |> Stream.map(&Map.get(&1, "data"))
    |> Stream.map(&type/1)
    |> Task.async_stream(&linkToArticle(client, &1),
      max_concurrency: 25,
      timeout: 10000
    )
    |> Stream.map(&item/1)
    |> Stream.reject(&is_nil/1)
    |> Enum.reduce([], fn res, acc -> [res | acc] end)
    |> feed(conn.request_path, now)
    |> XmlBuilder.generate()
    |> (&Conn.send_resp(conn, 200, &1)).()
  end

  def handle_reddit_resp({:error, err}, _client, conn) do
    Conn.send_resp(conn, 500, Jason.DecodeError.message(err))
  end

  defp type(item) do
    %{"url" => url} = item
    m = MIME.from_path(url)

    cond do
      String.starts_with?(m, "image/") ->
        {:image, item}

      String.contains?(url, "gfycat") or
          (String.contains?(url, "imgur") and String.ends_with?(url, "gifv")) ->
        {:opengraph, item}

      Reddit.is_media(item) ->
        {:media, item}

      true ->
        {:unknown, item}
    end
  end

  defp opengraph_request({:ok, content}) do
    Floki.parse_document(content.body)
  end

  defp opengraph_response({:ok, html}) do
    meta =
      &(Floki.find(html, &1)
        |> Floki.attribute("content")
        |> List.first())

    """
    <div>
      <iframe src="<%= vid %>" width="<%= width %>" height="<%= height %>"/>
      <img src="<%= img %>" class="webfeedsFeaturedVisual"/>
    </div>
    """
    |> EEx.eval_string(
      img: meta.("meta[property=\"og:image\"][content$=\".jpg\"]"),
      vid: meta.("meta[property=\"og:video\"]"),
      width: meta.("meta[property=\"og:video:width\"]"),
      height: meta.("meta[property=\"og:video:height\"]")
    )
  end

  defp linkToArticle(client, {:opengraph, item}) do
    item
    |> Map.get("url")
    |> client.inspect()
    |> opengraph_request()
    |> opengraph_response()
    |> comments(item)
    |> (&Map.put(item, "desc", &1)).()
  end

  defp linkToArticle(_client, {:media, item}) do
    Reddit.media(item)
    |> comments(item)
    |> (&Map.put(item, "desc", &1)).()
  end

  defp linkToArticle(_client, {:image, item}) do
    "<img src=\"#{item["url"]}\" />"
    |> comments(item)
    |> (&Map.put(item, "desc", &1)).()
  end

  defp linkToArticle(client, {:unknown, item}) do
    item
    |> get_in(~w(url))
    |> client.inspect()
    |> description()
    |> comments(item)
    |> (&Map.put(item, "desc", &1)).()
  end

  defp comments(desc, %{"permalink" => link}) do
    """
    <div>
      <div> <a href="https://www.reddit.com<%= link %>"> comments </a> </div>
      <%= desc %>
    <div>
    """
    |> EEx.eval_string(desc: desc, link: link)
  end

  defp description({:ok, resp}) do
    try do
      resp.body
      |> Readability.article()
      |> Readability.raw_html()
    rescue
      _ -> ""
    end
  end

  defp description({:error, _}) do
    ""
  end

  defp item({:ok, art}) do
    {:item, %{},
     [
       {:guid, %{}, Reddit.id(art)},
       {:title, %{}, Reddit.title(art)},
       {:link, %{}, Reddit.link(art)},
       {:pubDate, %{}, Reddit.pubDate(art)},
       XmlBuilder.element("content:encoded", {:cdata, art["desc"]})
     ]}
  end

  defp item({:error, _}) do
    nil
  end

  defp feed(items, path, now) do
    {:rss,
     %{
       "version" => "2.0",
       "xmlns:content" => "http://purl.org/rss/1.0/modules/content/"
     },
     [
       {:channel, %{},
        [
          {:title, %{}, "reddit-rss #{path}"},
          {:link, %{}, "https://github.com/trashhalo/reddit-rss"},
          {:pubDate, %{}, now},
          {:lastBuildDate, %{}, now},
          {:description, %{}, "Reddit RSS feed that links directly to the content"},
          {:managingEditor, %{}, "solka@hey.com (Stephen Solka)"}
        ] ++ items}
     ]}
    |> XmlBuilder.document()
  end
end
