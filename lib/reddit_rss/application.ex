defmodule RedditRss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: RedditRss.Router,
        options: [port: 8080]
      ),
      RedditRss.Client.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RedditRss.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
