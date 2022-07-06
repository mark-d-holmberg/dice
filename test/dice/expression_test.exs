defmodule Dice.ExpressionTest do
  use ExUnit.Case
  use Test.Support.DataCase

  alias Dice.{Expression, Builder, Rollable}
  doctest Expression

  # Automatically tests the Buildable mixin
  use Dice.Support.BuildableTestHelper,
    model: Expression,
    required_keys: [raw: "1d6", quantity: "1", sides: "6"]

  describe ":simple expressions" do
    test "DataCase.samples(:simple) recognizes the most basic expressions" do
      samples(:simple)
      |> Enum.each(fn sample ->
        assert {:ok, %Rollable{expressable: %Expression{raw: _sample}}} = Expression.build(sample)
      end)
    end
  end

  describe ":simple expressions with multipliers and parens" do
    test "(1d4*2)" do
      assert {:ok,
              %Rollable{
                expressable: %Expression{raw: "(1d4*2)", multiplier: 2, quantity: 1, sides: 4}
              }} = Expression.build("(1d4*2)")
    end
  end

  describe "struct setup" do
    test "it can store the quantity as an Expression" do
      assert {:ok,
              %Rollable{
                expressable: %Builder{
                  quantity: nil,
                  quantity_expression: %Expression{
                    d: :d,
                    raw: "2d8",
                    quantity: 2,
                    sides: 8
                  },
                  raw: "(2d8)d10",
                  sides: 10,
                  sides_expression: nil,
                  type: :complex
                }
              }} = Expression.build("(2d8)d10")
    end

    test "right parens" do
      {:ok,
       %Rollable{
         expressable: %Builder{
           quantity: 5,
           quantity_expression: nil,
           raw: "5d(1d6)",
           sides: nil,
           sides_expression: %Expression{
             d: :d,
             raw: "1d6",
             quantity: 1,
             sides: 6
           },
           type: :complex
         }
       }} = Expression.build("5d(1d6)")
    end
  end
end
