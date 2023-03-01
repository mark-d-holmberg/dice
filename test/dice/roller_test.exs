defmodule Dice.RollerTest do
  use ExUnit.Case

  alias Dice.{Expression, Roller, Modifier, Die, Result, Tray}

  doctest Roller

  setup do
    {:ok, %{"range_d20" => 1..20}}
  end

  describe "roll/1" do
    test "it can roll a d20", %{"range_d20" => valid} do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 1,
          raw: "d20",
          sides: 20
        },
        total: expected
      } = Roller.roll("d20")

      assert Enum.member?(valid, expected)
    end

    test "it can roll a 1d20", %{"range_d20" => valid} do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 1,
          raw: "1d20",
          sides: 20
        },
        total: expected
      } = Roller.roll("1d20")

      assert Enum.member?(valid, expected)
    end

    test "it can roll two d20 dice" do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 2,
          raw: "2d20",
          sides: 20
        },
        total: expected
      } = Roller.roll("2d20")

      assert Enum.member?(2..40, expected)
    end

    test "it can roll two d20 dice at advantage" do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 2,
          raw: "2d20",
          sides: 20
        },
        modifiers: [%Modifier{kind: :keep_highest, raw: "2d20", take: 1}],
        kept_rolls: _kept_rolls,
        total: expected
      } = Roller.roll("2d20kh")

      assert Enum.member?(1..20, expected)
    end

    test "it can roll two d20 dice at disadvantage", %{"range_d20" => valid} do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 2,
          raw: "2d20",
          sides: 20
        },
        modifiers: [%Modifier{kind: :keep_lowest, raw: "2d20", take: 1}],
        rolls: _all_rolls,
        kept_rolls: %Tray{items: [%Die{rolled: expected, faces: 20}], kind: "kept_rolls"},
        total: expected
      } = Roller.roll("2d20kl")

      assert Enum.member?(valid, expected)
    end

    test "it can roll multiple dice and only keep the highest of a specified number of dice" do
      %Result{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 10,
          raw: "10d4",
          sides: 4
        },
        modifiers: [%Modifier{kind: :keep_highest, raw: "10d4", take: 3}],
        rolls: all_rolls,
        kept_rolls: %Tray{items: kept_rolls, kind: "kept_rolls"},
        total: _total
      } = Roller.roll("10d4kh3")

      assert 10 = length(all_rolls)
      assert 3 = length(kept_rolls)

      dice_spread = Enum.map(all_rolls, fn %Die{rolled: rolled} -> rolled end)

      Enum.each(dice_spread, fn x ->
        assert Enum.member?(1..4, x)
      end)
    end

    test "it can roll multiple dice and only keep the lowest of a specified number of dice" do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 12,
          raw: "12d20",
          sides: 20
        },
        kept_rolls: %Tray{items: kept_rolls, kind: "kept_rolls"},
        modifiers: [%Modifier{kind: :keep_lowest, raw: "12d20", take: take}],
        rolls: rolls,
        total: total
      } = Roller.roll("12d20kl3")

      assert 12 = length(rolls)
      assert 3 = length(kept_rolls)
      assert 3 = take

      dice_spread = Enum.map(rolls, fn %Die{rolled: rolled} -> rolled end)
      kept_dice_spread = Enum.map(kept_rolls, fn %Die{rolled: rolled} -> rolled end)

      Enum.each(dice_spread, fn x ->
        assert Enum.member?(1..20, x)
      end)

      assert Enum.sum(kept_dice_spread) == total
    end
  end

  describe "roll/1 with composable expressions" do
    test "1d(1d20)", %{"range_d20" => valid} do
      # Roll a single dice where the max of that dice is 20, min should probably be 2
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 1,
          raw: _,
          sides: sides
        },
        total: expected
      } = Roller.roll("1d(1d20)")

      assert Enum.member?(valid, sides)
      assert Enum.member?(valid, expected)
    end

    test "(2d4)d8" do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: quantity,
          sides: 8
        },
        total: total
      } = Roller.roll("(2d4)d8")

      assert Enum.member?(1..8, quantity)
      assert Enum.member?(1..64, total)
    end

    test "(1d20*2)d(1d10)" do
      %{
        expression: %Expression{
          d: :d,
          multiplier: nil,
          sides: sides
        },
        total: total
      } = Roller.roll("(1d20*2)d(1d10)")

      assert Enum.member?(1..10, sides)
      assert Enum.member?(1..360, total)
    end
  end

  describe "roll/1 with count successes" do
    test "> 10" do
      Roller.roll("{6d6, 5d8, 4d10, 3d12}cs>10")
      |> Enum.each(fn x -> assert x.total > 10 end)
    end

    test ">= 10" do
      Roller.roll("{6d6, 5d8, 4d10, 3d12}cs>=10")
      |> Enum.each(fn x -> assert x.total >= 10 end)
    end

    test "<= 10" do
      Roller.roll("{6d6, 5d8, 4d10, 3d12}cs<=10")
      |> Enum.each(fn x -> assert x.total <= 10 end)
    end

    test "< 10" do
      Roller.roll("{6d6, 5d8, 4d10, 3d12}cs<10")
      |> Enum.each(fn x -> assert x.total < 10 end)
    end

    test "= 10" do
      Roller.roll("{6d6, 5d8, 4d10, 3d12}cs=10")
      |> Enum.each(fn x -> assert x.total == 10 end)
    end
  end

  describe "roll/1 with margin success" do
    test "3d12ms>(20)" do
      Roller.roll("3d12ms>(15)")
    end

    test "3d12ms>(4d6)" do
      Roller.roll("3d12ms>(4d6)")

      # %Dice.Result{
      #   expression: %Dice.Expression{
      #     d: :d,
      #     flat_value: nil,
      #     multiplier: nil,
      #     quantity: 3,
      #     raw: "3d12",
      #     sides: 12
      #   },
      #   kept_rolls: [
      #     %Dice.Die{faces: 12, rolled: 8},
      #     %Dice.Die{faces: 12, rolled: 11},
      #     %Dice.Die{faces: 12, rolled: 11}
      #   ],
      #   margin_dc_dice: [%Dice.Die{faces: nil, rolled: 15}],
      #   margin_of_success: 15,
      #   modifiers: [
      #     %Dice.Modifier{
      #       kind: :margin_success,
      #       operator: ">",
      #       raw: "3d12",
      #       take: %Dice.Rollable{
      #         expressable: %Dice.Expression{
      #           d: :d,
      #           flat_value: nil,
      #           multiplier: nil,
      #           quantity: 4,
      #           raw: "(4d6)",
      #           sides: 6
      #         },
      #         modifiers: [],
      #         raw: "(4d6)"
      #       }
      #     }
      #   ],
      #   rolls: [
      #     %Dice.Die{faces: 12, rolled: 8},
      #     %Dice.Die{faces: 12, rolled: 11},
      #     %Dice.Die{faces: 12, rolled: 11}
      #   ],
      #   total: 30
      # }
    end
  end

  describe "roll/1 with wild dice" do
    test "it can roll a 1d8x wild dice" do
      %Result{
        expression: %Expression{
          d: :d,
          flat_value: nil,
          multiplier: nil,
          quantity: 1,
          raw: "1d8",
          sides: 8
        },
        kept_rolls: %Tray{
          items: _,
          kind: "kept_rolls"
        },
        margin_dc_dice: [],
        margin_of_success: nil,
        modifiers: [
          %Modifier{kind: :wild_dice, operator: nil, raw: "1d8", take: nil}
        ],
        rolls: [%Die{faces: 8, rolled: _}],
        total: _foo
      } = Roller.roll("1d8x")
    end
  end

  describe "roll/1 with added modifiers" do
    test "it can roll 1d1 + 5" do
      assert %Result{
               total: 6,
               modifiers: [
                 %Modifier{kind: :roll_modifier_addition, operator: nil, raw: "1d1+5", take: 5}
               ],
               rolls: [%Die{faces: 1, rolled: 1}]
             } = Roller.roll("1d1+5")
    end

    test "it can roll 1d2 + 3" do
      %Result{
        total: total,
        modifiers: [
          %Modifier{kind: :roll_modifier_addition, operator: nil, raw: "1d2+3", take: 3}
        ],
        rolls: [%Die{faces: 2, rolled: rolled}]
      } = Roller.roll("1d2+3")

      assert Enum.member?(1..2, rolled)
      assert Enum.member?(4..5, total)
    end
  end

  describe "roll/1 with subtracted modifiers" do
    test "it can roll 1d1 - 5" do
      assert %Result{
               total: -4,
               modifiers: [
                 %Modifier{
                   kind: :roll_modifier_subtraction,
                   operator: nil,
                   raw: "1d1-5",
                   take: -5
                 }
               ],
               rolls: [%Die{faces: 1, rolled: 1}]
             } = Roller.roll("1d1-5")
    end

    test "it can roll 1d2 - 3" do
      %Result{
        total: total,
        modifiers: [
          %Modifier{kind: :roll_modifier_subtraction, operator: nil, raw: "1d2-3", take: -3}
        ],
        rolls: [%Die{faces: 2, rolled: rolled}]
      } = Roller.roll("1d2-3")

      assert Enum.member?(1..2, rolled)
      assert Enum.member?(-1..-2, total)
    end
  end
end

# https://foundryvtt.com/article/dice-advanced/

# Dice.Roller.roll("{3d12}cs<=15")  (it has to be in braces)
# /roll 3d12cs<=(@attributes.power) # CS is count-successes vs a number

# Get the margin of success based on an opposed roll of 4d6.
# This modifier subtracts a target value set by the user from the result of the dice rolled, and returns the difference
# as the final total. If the amount rolled is less than the target it outputs a negative number, and a positive number
# if there is a remainder after the subtraction.
# /roll 3d12ms>(4d6)

# [X] This works.
# Roll 4d6, 3d8, and 2d10, keep only the highest result.
# /roll {4d6, 3d8, 2d10}kh

# [X] This works.
# Roll one twenty sided die and the result can only be 10 or higher.
# /roll {1d20, 10}kh #

# [X] This works.
# DND5e - Character Creation: roll a pool of ability scores when creating your character.
# /roll {4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3} # Character Ability Scores

# Roll 6d6, 5d8, 4d10, 3d12 and count how many resolve to greater than 15.
# /roll {6d6, 5d8, 4d10, 3d12}cs>15

# SWADE - Wild Die: roll one eight-sided die and one six-sided die, both of which will roll additional dice of the same size if they roll their maximum value. Use the highest result of rolls.
# /roll {1d8x, 1d6x}kh

# For example in this screenshot from the dnd5e system, by rolling /roll 1d20 + @abilities.cha.mod you would perform a check of your selected token's Charisma modifier.
# /roll 1d20 + @abilities.cha.mod you would perform a check of your selected token's Charisma modifier.
