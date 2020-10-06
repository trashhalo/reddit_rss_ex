defmodule RedditRss.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger
  alias RedditRss.Client

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  match _ do
    IO.iodata_to_binary([conn.request_path, conn.query_string])
    |> Client.get()
    |> RedditRss.Rss.handle_reddit_resp(Client, conn)
  end
end
