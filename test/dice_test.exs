defmodule DiceTest do
  use ExUnit.Case
  doctest Dice

  describe "ability_scores/1" do
    test "defaults to the standard formula" do
      # You can only get between a min of 3 and a max of 18
      Dice.ability_scores()
      |> Enum.each(fn x ->
        assert Enum.member?(3..18, x)
      end)
    end
  end
end
