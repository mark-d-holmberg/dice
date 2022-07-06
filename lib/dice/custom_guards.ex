defmodule Dice.CustomGuards do
  @moduledoc """
  A set of custom Elixir Guard clauses for brevity.

  Importing this module into your own module is as easy as:

  ## If you want everything
  `import Dice.CustomGuards`

  ## If you only want a specific guard
  `import Dice.CustomGuards, only: [binary_present: 1]`
  """

  @doc """
  Checks against the value being a binary string and the byte_size being greater than zero
  """
  defguard binary_present(string) when is_binary(string) and byte_size(string) > 0

  @doc """
  Checks against the value being a binary string and the byte_size being exactly zero
  """
  defguard binary_zero(string) when is_binary(string) and byte_size(string) == 0
end
