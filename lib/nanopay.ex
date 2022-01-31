defmodule Nanopay do
  @moduledoc """
  Nanopay keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @regexes %{
    email: ~r/\A[^@\s]+@[^@\s]+\z/,
    handle: ~r/\A[\w]+\z/,
    keypath: ~r/\A(\/[a-z0-9]+)+\z/,
    pubkey: ~r/\A([0-9a-f]{2}){33}\z/i,
    sha256hex: ~r/\A([0-9a-f]{2}){32}\z/i
  }

  @doc """
  Returns a a regex for the given key, for use in validations.
  """
  @spec regex(atom()) :: Regex.t()
  def regex(key), do: Map.get(@regexes, key)

end
