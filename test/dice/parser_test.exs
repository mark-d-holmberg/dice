defmodule Dice.ParserTest do
  use ExUnit.Case

  alias Dice.{Parser, Builder, Expression, Rollable}

  doctest Parser

  describe "parse/1 and Rollable" do
    test "it accepts a %Rollable{} struct with no modifiers" do
      assert {:ok,
              %Rollable{
                expressable: %Expression{
                  d: :d,
                  multiplier: nil,
                  quantity: 1,
                  raw: "1d4",
                  sides: 4
                }
              }} = Parser.parse(%Rollable{raw: "1d4", modifiers: nil})
    end

    test "it accepts a %Rollable{} struct with addition modifiers" do
      assert {:ok,
              %Rollable{
                expressable: %Expression{
                  d: :d,
                  multiplier: nil,
                  quantity: 1,
                  raw: "1d1+5",
                  sides: 1
                }
              }} = Parser.parse(%Rollable{raw: "1d1+5"})
    end
  end

  describe "parse/1 with :complex_multiplier expressions" do
    test "(1d20*2)d(1d10)" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: nil,
                  quantity_expression: %Expression{
                    d: :d,
                    multiplier: 2,
                    quantity: 1,
                    raw: "1d20*2",
                    sides: 20
                  },
                  raw: "(1d20*2)d(1d10)",
                  sides: nil,
                  sides_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 1,
                    raw: "1d10",
                    sides: 10
                  },
                  type: :complex
                }
              }} = Parser.parse("(1d20*2)d(1d10)")
    end

    test "(1d20*2)d20" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: nil,
                  quantity_expression: %Expression{
                    d: :d,
                    multiplier: 2,
                    quantity: 1,
                    raw: "1d20*2",
                    sides: 20
                  },
                  raw: "(1d20*2)d20",
                  sides: nil,
                  sides_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 1,
                    raw: "d20",
                    sides: 20
                  },
                  type: :complex
                }
              }} = Parser.parse("(1d20*2)d20")
    end

    test "(1d4)d(2d8)" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: nil,
                  quantity_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 1,
                    raw: "1d4",
                    sides: 4
                  },
                  raw: "(1d4)d(2d8)",
                  sides: nil,
                  sides_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 2,
                    raw: "2d8",
                    sides: 8
                  },
                  type: :complex
                }
              }} = Parser.parse("(1d4)d(2d8)")
    end

    test "(1d4)d20" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: nil,
                  quantity_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 1,
                    raw: "1d4",
                    sides: 4
                  },
                  raw: "(1d4)d20",
                  sides: 20,
                  sides_expression: nil,
                  type: :complex
                }
              }} = Parser.parse("(1d4)d20")
    end

    test "6d(2d12)" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: 6,
                  quantity_expression: nil,
                  raw: "6d(2d12)",
                  sides: nil,
                  sides_expression: %Expression{
                    d: :d,
                    multiplier: nil,
                    quantity: 2,
                    raw: "2d12",
                    sides: 12
                  },
                  type: :complex
                }
              }} = Parser.parse("6d(2d12)")
    end
  end
end
