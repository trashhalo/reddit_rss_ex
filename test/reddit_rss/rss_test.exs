defmodule RedditRss.RssTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias RedditRss.Rss

  import Mox
  doctest RedditRss.Rss

  setup :verify_on_exit!

  defp resp(val) do
    item = for {key, val} <- val, into: %{}, do: {Atom.to_string(key), val}

    {:ok,
     %{
       "data" => %{
         "children" => [
           %{
             "data" => item
           }
         ]
       }
     }}
  end

  test "text article" do
    client =
      RedditRss.MockHttp
      |> expect(:inspect, fn _ ->
        {:ok,
         """
           <html>
           <body>
             <p> Hello World </p>
           </body>
           </html>
         """}
      end)

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://fake.z",
        media: nil,
        secure_media: nil,
        media_embed: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://fake.z",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  \n<div>"
           }
  end

  test "media url is image" do
    client = RedditRss.MockHttp

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://fake.z/cat.png",
        media: nil,
        secure_media: nil,
        media_embed: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://fake.z/cat.png",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  <img src=\"http://fake.z/cat.png\" />\n<div>"
           }
  end

  test "media key present" do
    client = RedditRss.MockHttp

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://fake.z/cat",
        media: %{
          "oembed" => %{
            "html" => "&lt;iframe&gt;&lt;/iframe&gt;"
          }
        },
        secure_media: nil,
        media_embed: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://fake.z/cat",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  <iframe></iframe>\n<div>"
           }
  end

  test "media_embed key present" do
    client = RedditRss.MockHttp

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://fake.z/cat",
        media_embed: %{
          "content" => "&lt;iframe&gt;&lt;/iframe&gt;"
        },
        secure_media: nil,
        media: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://fake.z/cat",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  <iframe></iframe>\n<div>"
           }
  end

  test "secure_media key present" do
    client = RedditRss.MockHttp

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://fake.z/cat",
        secure_media: %{
          "oembed" => %{
            "html" => "&lt;iframe&gt;&lt;/iframe&gt;"
          }
        },
        media: nil,
        media_embed: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://fake.z/cat",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  <iframe></iframe>\n<div>"
           }
  end

  test "opengraph link" do
    client =
      RedditRss.MockHttp
      |> expect(:inspect, fn _ ->
        {:ok,
         %{
           body: """
             <html>
             <head>
              <meta property="og:image" content="https://thumbs.gfycat.com/BlackVigorousApe-mobile.jpg"/>
              <meta property="og:video" content="https://thumbs.gfycat.com/BlackVigorousApe-mobile.mp4"/>
              <meta property="og:video:width" content="800"/>
              <meta property="og:video:height" content="600"/>
             </head>
             <body>
               <p> Hello World </p>
             </body>
             </html>
           """
         }}
      end)

    conn = conn(:get, "/r/android.json")

    resp =
      resp(
        id: "abc",
        title: "def",
        created: 1_601_838_688,
        url: "http://gfycat.com",
        media: nil,
        secure_media: nil,
        media_embed: nil,
        permalink: "/r/abcd"
      )

    {status, _, body} =
      Rss.handle_reddit_resp(resp, client, conn)
      |> sent_resp()

    item =
      XmlToMap.naive_map(body)
      |> get_in(~w(rss #content channel item))

    assert status == 200

    assert item == %{
             "guid" => "abc",
             "link" => "http://gfycat.com",
             "pubDate" => "Sun, 4 Oct 2020 19:11:28 +0000",
             "title" => "def",
             "{http://purl.org/rss/1.0/modules/content/}encoded" =>
               "<div>\n  <div> <a href=\"https://www.reddit.com/r/abcd\"> comments </a> </div>\n  <div>\n  <iframe src=\"https://thumbs.gfycat.com/BlackVigorousApe-mobile.mp4\" width=\"800\" height=\"600\"/>\n  <img src=\"https://thumbs.gfycat.com/BlackVigorousApe-mobile.jpg\" class=\"webfeedsFeaturedVisual\"/>\n</div>\n\n<div>"
           }
  end
end
