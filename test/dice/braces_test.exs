defmodule Dice.BracesTest do
  use ExUnit.Case

  alias Dice.Braces
  doctest Braces

  describe "expressions_from_braces/1" do
    test "it works with comma separated values" do
      assert [
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 1,
                   raw: "1d10",
                   sides: 10
                 },
                 modifiers: [],
                 raw: "1d10"
               },
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 2,
                   raw: "2d6",
                   sides: 6
                 },
                 modifiers: [],
                 raw: "2d6"
               },
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 3,
                   raw: "3d12",
                   sides: 12
                 },
                 modifiers: [],
                 raw: "3d12"
               }
             ] =
               Braces.expressions_from_braces("1d10, 2d6, 3d12")
               |> Task.await()
    end
  end

  describe "handle_braces/2" do
    test "outer count_success" do
      {regex, kind} =
        Dice.Grammar.all_patterns() |> Enum.find(fn {_x, y} -> y == :count_success end)

      assert {:ok,
              [
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 6,
                    raw: "6d6",
                    sides: 6
                  },
                  modifiers: [],
                  raw: "6d6"
                },
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 5,
                    raw: "5d8",
                    sides: 8
                  },
                  modifiers: [],
                  raw: "5d8"
                },
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 4,
                    raw: "4d10",
                    sides: 10
                  },
                  modifiers: [],
                  raw: "4d10"
                },
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 3,
                    raw: "3d12",
                    sides: 12
                  },
                  modifiers: [],
                  raw: "3d12"
                }
              ],
              %Dice.Modifier{
                kind: :count_success,
                operator: ">",
                raw: "6d6, 5d8, 4d10, 3d12",
                take: 15
              }} = Braces.handle_braces({regex, kind}, "{6d6, 5d8, 4d10, 3d12}cs>15")
    end

    test "braces_no_outer_modifiers inside only" do
      {regex, kind} =
        Dice.Grammar.all_patterns()
        |> Enum.find(fn {_x, y} -> y == :braces_no_outer_modifiers end)

      assert [
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 2,
                   raw: "2d10",
                   sides: 10
                 },
                 modifiers: [],
                 raw: "2d10"
               },
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 4,
                   raw: "4d8",
                   sides: 8
                 },
                 modifiers: [
                   %Dice.Modifier{kind: :keep_highest, operator: nil, raw: "4d8", take: 2}
                 ],
                 raw: "4d8"
               },
               %Dice.Rollable{
                 expressable: %Dice.Expression{
                   d: :d,
                   flat_value: nil,
                   multiplier: nil,
                   quantity: 20,
                   raw: "20d6",
                   sides: 6
                 },
                 modifiers: [
                   %Dice.Modifier{kind: :keep_highest, operator: nil, raw: "20d6", take: 3}
                 ],
                 raw: "20d6"
               }
             ] = Braces.handle_braces({regex, kind}, "{2d10, 4d8kh2, 20d6kh3}")
    end

    test "braces_with_maybe_modifier outside" do
      {regex, kind} =
        Dice.Grammar.all_patterns()
        |> Enum.find(fn {_x, y} -> y == :braces_with_maybe_modifier end)

      assert {:ok,
              [
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 2,
                    raw: "2d10",
                    sides: 10
                  },
                  modifiers: [],
                  raw: "2d10"
                },
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 4,
                    raw: "4d8",
                    sides: 8
                  },
                  modifiers: [
                    %Dice.Modifier{kind: :keep_highest, operator: nil, raw: "4d8", take: 2}
                  ],
                  raw: "4d8"
                },
                %Dice.Rollable{
                  expressable: %Dice.Expression{
                    d: :d,
                    flat_value: nil,
                    multiplier: nil,
                    quantity: 20,
                    raw: "20d6",
                    sides: 6
                  },
                  modifiers: [
                    %Dice.Modifier{kind: :keep_highest, operator: nil, raw: "20d6", take: 3}
                  ],
                  raw: "20d6"
                }
              ],
              %Dice.Modifier{kind: :keep_highest, operator: nil, raw: "2d10, 4d8", take: 2}} =
               Braces.handle_braces({regex, kind}, "{2d10, 4d8kh2, 20d6kh3}kh2")
    end
  end
end
