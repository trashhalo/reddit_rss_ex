defmodule RedditRss.Client do
  @behaviour RedditRss.Http

  alias Finch.Response

  @spec child_spec :: {Finch, [{:name, RedditRss.Client} | {:pools, map}, ...]}
  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       :default => [size: 25]
     }}
  end

  @impl RedditRss.Http
  def get(path) do
    request(path)
    |> parse
  end

  @impl RedditRss.Http
  def inspect(url) do
    :get
    |> Finch.build(url)
    |> Finch.request(__MODULE__)
  end

  defp request(path) do
    :get
    |> Finch.build("https://www.reddit.com#{path}")
    |> Finch.request(__MODULE__)
  end

  defp parse({:ok, %Response{body: body}}) do
    Jason.decode(body)
  end
end
