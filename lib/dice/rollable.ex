defmodule Dice.Rollable do
  @moduledoc """
  Represents an unrolled polyhedral die
  """
  use Dice.ContextClient

  defstruct raw: nil, modifiers: nil, expressable: nil

  @type expressable :: Expression.t() | Builder.t() | nil

  @typedoc "Represents something which can be 'rolled'"
  @type t :: %__MODULE__{
          raw: String.t(),
          modifiers: [Modifier.t()],
          expressable: expressable()
        }

  @doc """
  Build a new struct
  """
  @spec build(String.t()) :: {:ok, t()}
  def build(raw) when binary_present(raw) do
    {:ok, %__MODULE__{raw: raw, modifiers: []}}
  end

  @doc """
  Adds another modifier to the Rollable struct

  ## Examples
      iex> Dice.Rollable.add_modifier(%Dice.Rollable{modifiers: [], raw: "1d4"}, %Dice.Modifier{kind: :keep_highest, raw: "2d4kh"})
      %Dice.Rollable{
        modifiers: [%Dice.Modifier{kind: :keep_highest, raw: "2d4kh"}],
        raw: "1d4"
      }

  """
  @spec add_modifier(Rollable.t(), Modifier.t()) :: Rollable.t()
  def add_modifier(%Rollable{modifiers: nil} = rollable, my_modifier) do
    %Rollable{rollable | modifiers: [my_modifier]}
  end

  def add_modifier(%Rollable{modifiers: modifiers} = rollable, my_modifier) do
    %Rollable{rollable | modifiers: modifiers ++ [my_modifier]}
  end
end
