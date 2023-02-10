defmodule Dice.ModifierTest do
  use ExUnit.Case

  alias Dice.{Expression, Modifier}
  doctest Modifier

  describe "scan/1" do
    test "(10d2*3)d(4d8)kh" do
      assert {:ok, %Modifier{kind: :keep_highest, raw: "(10d2*3)d(4d8)", take: 1}} =
               Modifier.scan("(10d2*3)d(4d8)kh")
    end

    test "(10d2*3)d(4d8)kh3 with a t ake value" do
      assert {:ok, %Modifier{kind: :keep_highest, raw: "(10d2*3)d(4d8)", take: 3}} =
               Modifier.scan("(10d2*3)d(4d8)kh3")
    end

    test "1d8x wild dice" do
      assert {:ok, %Modifier{kind: :wild_dice, raw: "1d8", take: nil, operator: nil}} =
               Modifier.scan("1d8x")
    end

    test "1d1+5" do
      assert {:ok,
              %Modifier{
                kind: :roll_modifier_addition,
                raw: "1d1+5",
                take: 5,
                operator: nil
              }} = Modifier.scan("1d1+5")
    end

    test "1d1-5" do
      assert {:ok,
              %Modifier{
                kind: :roll_modifier_subtraction,
                raw: "1d1-5",
                take: -5,
                operator: nil
              }} = Modifier.scan("1d1-5")
    end
  end

  describe "take can be an integer or an expression" do
    test "integer" do
      expected = %Modifier{kind: :keep_highest, raw: "(10d2*3)d(4d8)", take: 3}
      assert is_integer(expected.take)
    end

    test "expression" do
      expected = %Modifier{
        kind: :keep_highest,
        raw: "(10d2*3)d(4d8)",
        take: %Expression{
          d: :d,
          flat_value: 3,
          multiplier: nil,
          quantity: nil,
          raw: "3",
          sides: nil
        }
      }

      assert %Expression{} = expected.take
    end
  end
end
