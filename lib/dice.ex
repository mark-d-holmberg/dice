defmodule Dice do
  @moduledoc """
  Documentation for `Dice`.
  """
  use Dice.ContextClient

  @doc """
  Roll some dice.
  """
  @spec roll(String.t()) :: Result.t()
  def roll(raw) when binary_present(raw) do
    Roller.roll(raw)
  end

  @doc """
  Average dice formula

  ## Examples:
      iex> Dice.average_roll(20, 1)
      10.5

      iex> Dice.average_roll(10, 4)
      22.0
  """
  def average_roll(max_face_count, num_dice)
      when is_integer(max_face_count) and is_integer(num_dice) do
    (max_face_count + 1) / 2 * num_dice
  end

  @doc """
  Generate a list of ability scores.
  """
  @spec ability_scores() :: list()
  def ability_scores() do
    "{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}"
    |> Roller.roll()
    |> Enum.map(& &1.total)
  end

  @doc """
  Returns a map of ability scores mapped to attribute names.
  """
  @spec ability_scores(:dnd) :: map()
  def ability_scores(:dnd) do
    ["Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"]
    |> Enum.zip(ability_scores())
    |> Enum.into(%{})
  end
end
