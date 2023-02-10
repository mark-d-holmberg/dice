defmodule Dice.GrammarTest do
  use ExUnit.Case

  alias Dice.Grammar
  doctest Grammar

  describe "Grammar.matching? with braces" do
    test "With a KH modifier" do
      # "2d20kh"
      # @keep_regex ~r/\{?(?<expression>.+?)\}?(?<modifier>(kh|kl))(?<take>\d+)?/
      assert [{_, :keep_amount}] = Grammar.matching?("2d20kh")
    end

    test "With a KL modifier" do
      # "2d20kl"
      # @keep_regex ~r/\{?(?<expression>.+?)\}?(?<modifier>(kh|kl))(?<take>\d+)?/
      assert [{_, :keep_amount}] = Grammar.matching?("2d20kl")
    end

    test "With a count_success modifier" do
      # "{1d4, 3d8}cs>5"
      # @count_success_braces_regex ~r/\{?(?<expression>.+[^\}])\}?(?<modifier>(cs))(?<operator>>|>=|<=|<|=)?(?<take>\d+)/
      assert [{_, :count_success}, {_, :braces_with_maybe_modifier}] =
               Grammar.matching?("{1d4, 3d8}cs>5")
    end

    test "With a margin_success modifier" do
      # "{1d4, 3d8}ms>(2d8)"
      # @margin_success_regex ~r/\{?(?<expression>.+[^\}])\}?(?<modifier>(ms))(?<operator>>|>=|<=|<|=)(?<take>.+)/
      assert [{_, :margin_success}, {_, :braces_with_maybe_modifier}] =
               Grammar.matching?("{1d4, 3d8}ms>(2d8)")
    end

    test "With a flat value" do
      # "1"
      # @flat_value_regex ~r/^\(?(?<flat_value>\d+)\)?$/
      assert [{_, :flat_value}] = Grammar.matching?("1")
    end

    test "With a simple form" do
      # "1d4"
      # @simple_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\)?$/
      assert [{_, :simple}] = Grammar.matching?("1d4")
    end

    test "With an only_sides form" do
      # "d20"
      # @only_sides_regex ~r/^d(?<sides>\d+)\)?$/
      assert [{_, :only_sides}] = Grammar.matching?("d20")
    end

    test "With a multiplier" do
      # "(1d20*2)"
      # @multiplier_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\*(?<multiplier>\d+)\)?$/
      assert [{_, :multiplier}] = Grammar.matching?("(1d20*2)")
    end

    test "With count_success outside of braces" do
      # NOTE: Fairly certain the the "cs" part has to be outside the braces as per this regex
      # {6d6, 5d8, 4d10, 3d12}cs>15
      # {2d10, 4d8kh2, 20d6kh3}cs<15
      # {2d10, 4d8kh2, 20d6kh3}cs<=15
      # {2d10, 4d8kh2, 20d6kh3}cs>=15
      # {2d10, 4d8kh2, 20d6kh3}cs=15
      # @count_success_regex ~r/{(?<expression>.+)}(?<modifier>cs)?(?<operator>>|>=|<=|<|=)?(?<take>\d+)/
      assert [
               {_, :count_success},
               {_, :braces_with_maybe_modifier},
               {_, :keep_amount}
             ] = Grammar.matching?("{2d10, 4d8kh2, 20d6kh3}cs>15")
    end

    # TODO: this is broken
    test "With keep inside of braces" do
      # "{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}"
      # @braces_with_maybe_modifier_regex ~r/{(?<expression>.+)}(?<modifier>kh|kl)?(?<take>\d+)?/
      assert [{_, :braces_with_maybe_modifier}, {_, :keep_amount}] =
               Grammar.matching?("{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}")
    end

    test "With complex quantity multiplier in parenthesis" do
      # "(1d20*2)d(1d10)"
      # @complex_quantity_multiplier_regex ~r/^\(?(?<first_die>\d+d\d+\*(?<multiplier>\d+))\)?d\(?(?<second_die>\d+d\d+)\)?$/
      assert [{_, :complex_quantity_multiplier}] = Grammar.matching?("(1d20*2)d(1d10)")
    end

    test "With complex quantity multiplier ends with" do
      # "(1d20*2)d20"
      # @complex_multiplier_ends_with ~r/^\(?(?<first_die>\d+d\d+\*(?<multiplier>\d+))\)(?<ends_with>d\d+)$/
      assert [{_, :complex_multiplier_ends_with}] = Grammar.matching?("(1d20*2)d20")
    end

    test "With complex quantity and sides expressions" do
      # "(1d4)d(1d20)"
      # @complex_regex ~r/^\(?(?<first_die>\d+d\d+)\)?d\(?(?<second_die>\d+d\d+)\)?$/
      assert [{_, :complex}, {_, :starts_with}] = Grammar.matching?("(1d4)d(1d20)")
    end

    test "With starts_with" do
      # "(1d4)d20"
      # @starts_with ~r/^\((?<first_die>\d+d\d+)\)(?<ends_with>d.*)$/
      assert [{_, :starts_with}] = Grammar.matching?("(1d4)d20")
    end

    test "With ends_with" do
      # "6d(2d12)"
      # @ends_with ~r/^(?<quantity>\d+)d\((?<second_die>\d+d\d+)\)$/
      assert [{_, :ends_with}] = Grammar.matching?("6d(2d12)")
    end
  end

  describe "Grammar.matching?/1 outside of braces" do
    test "roll_modifier_addition 1d1+5" do
      assert [{_, :roll_modifier_addition}] = Grammar.matching?("1d1+5")
    end

    test "roll_modifier_subtraction 1d1-5" do
      assert [{_, :roll_modifier_subtraction}] = Grammar.matching?("1d1-5")
    end
  end
end
