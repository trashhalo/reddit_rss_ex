defmodule RedditRss.Helpers do
  def formatDate(date) do
    Timex.format!(date, "{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}:{s} {Z}")
  end
end
