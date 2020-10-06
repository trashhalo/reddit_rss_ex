defmodule RedditRss.MixProject do
  use Mix.Project

  def project do
    [
      app: :reddit_rss,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :timex, :mime],
      mod: {RedditRss.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:finch, "~> 0.3.2"},
      {:jason, "~> 1.2.2"},
      {:xml_builder, "~> 2.1.1"},
      {:timex, "~> 3.0"},
      {:mime, "~> 1.2"},
      {:readability, "~> 0.10.0"},
      {:html_entities, "~> 0.5.1"},
      {:floki, "~> 0.28.0"},
      {:mox, "~> 1.0", only: :test},
      {:elixir_xml_to_map, "~> 2.0", only: :test}
    ]
  end
end
