defmodule Dice.Die do
  @moduledoc """
  Represents an unrolled polyhedral die
  """
  use Dice.ContextClient

  defstruct faces: nil, rolled: nil

  @typedoc "What types are allowed as parameters to `build/1`"
  @type buildable_type :: integer() | list()

  @typedoc "Represents the number of faces on a Die and what value was rolled, if applicable"
  @type t :: %__MODULE__{
          faces: integer(),
          rolled: integer()
        }

  @doc """
  Build a new struct which represents the number of faces for the die and what value is rolled

  ## Examples
      iex> Die.build(8)
      {:ok, %Dice.Die{rolled: nil, faces: 8}}

      iex> Die.build([faces: 8])
      {:ok, %Dice.Die{rolled: nil, faces: 8}}
  """
  @spec build(buildable_type()) :: {:ok, t()}
  def build(faces) when is_integer(faces), do: build(faces: faces)

  def build(opts) when is_list(opts) do
    {:ok, struct(__MODULE__, opts)}
  end
end
