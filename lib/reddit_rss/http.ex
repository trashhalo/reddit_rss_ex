defmodule RedditRss.Http do
  @callback get(any) :: {:error, Jason.DecodeError.t()} | {:ok, any}
  @callback inspect(binary | URI.t()) ::
              {:error, %{:reason => any, optional(:module) => any}}
              | {:ok, Finch.Response.t()}
end
