defmodule Dice.BuilderTest do
  use ExUnit.Case

  alias Dice.{Expression, Builder}

  doctest Builder

  describe "matching?/1" do
    test "1d4" do
      assert {_, :simple} = Builder.matching?("1d4")
    end

    test "d20" do
      assert {_, :only_sides} = Builder.matching?("d20")
    end

    test "1d20*2" do
      assert {_, :multiplier} = Builder.matching?("1d20*2")
    end

    test "no match (1d4)d20" do
      assert is_nil(Builder.matching?("(1d4)d20"))
    end
  end

  describe "guess/1 with :simple expressions" do
    test "d20" do
      assert {:ok, %Expression{d: :d, raw: "d20", quantity: 1, sides: 20}} = Builder.guess("d20")
    end

    test "1d4" do
      assert {:ok, %Expression{d: :d, raw: "1d4", quantity: 1, sides: 4}} = Builder.guess("1d4")
    end

    test "double digits for sides like 2d20" do
      assert {:ok, %Expression{d: :d, raw: "2d20", quantity: 2, sides: 20}} =
               Builder.guess("2d20")
    end

    test "double digits for quantity" do
      assert {:ok, %Expression{d: :d, raw: "20d4", quantity: 20, sides: 4}} =
               Builder.guess("20d4")
    end

    test "double digits on both sides" do
      assert {:ok, %Expression{d: :d, raw: "20d10", quantity: 20, sides: 10}} =
               Builder.guess("20d10")
    end
  end

  describe "guess/1 with :complex single expressions" do
    test "it can handle basic parenthesis" do
      assert {:ok, %Expression{d: :d, raw: "(1d4)", quantity: 1, sides: 4}} =
               Builder.guess("(1d4)")
    end

    test "(2d20)" do
      assert {:ok, %Expression{d: :d, raw: "(2d20)", quantity: 2, sides: 20}} =
               Builder.guess("(2d20)")
    end

    test "(20d4) double digits for quantity" do
      assert {:ok, %Expression{d: :d, raw: "(20d4)", quantity: 20, sides: 4}} =
               Builder.guess("(20d4)")
    end

    test "(20d10) double digits on both sides" do
      assert {:ok, %Expression{d: :d, raw: "(20d10)", quantity: 20, sides: 10}} =
               Builder.guess("(20d10)")
    end
  end

  describe "guess/1 with :complex quantity simple sides expressions" do
    test "(1d4)d20" do
      assert {:ok,
              %Builder{
                quantity: nil,
                quantity_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                raw: "(1d4)d20",
                sides: nil,
                sides_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                type: :complex
              }} = Builder.guess("(1d4)d20")
    end

    test "4d(1d10)" do
      assert {:ok,
              %Builder{
                quantity: nil,
                quantity_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                raw: "4d(1d10)",
                sides: nil,
                sides_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                type: :complex
              }} = Builder.guess("4d(1d10)")
    end

    test "(1d20*2)d20" do
      assert {:ok,
              %Builder{
                quantity: nil,
                quantity_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                raw: "(1d20*2)d20",
                sides: nil,
                sides_expression: %Expression{
                  d: nil,
                  multiplier: nil,
                  quantity: nil,
                  raw: "",
                  sides: nil
                },
                type: :complex
              }} = Builder.guess("(1d20*2)d20")
    end
  end

  describe "distribute/1" do
    test "it can distribute an expression 1d(1d20)" do
      subject = %Builder{
        quantity: 1,
        quantity_expression: nil,
        raw: "1d(1d20)",
        sides: nil,
        sides_expression: %Expression{
          d: :d,
          raw: "1d20",
          quantity: 1,
          sides: 20
        },
        type: :complex
      }

      expected = Builder.distribute(subject)
      assert is_nil(expected.sides_expression)
      refute is_nil(expected.quantity)
      assert Enum.member?(Enum.into(1..20, []), expected.sides)
    end

    test "(1d4)d10" do
      subject = %Builder{
        quantity: nil,
        quantity_expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 1,
          raw: "1d4",
          sides: 4
        },
        raw: "(1d4)d10",
        sides: 10,
        sides_expression: nil,
        type: :complex
      }

      expected = Builder.distribute(subject)
      assert Enum.member?(1..4, expected.quantity)
      assert is_nil(expected.quantity_expression)
      assert is_nil(expected.sides_expression)
      assert 10 = expected.sides
    end

    test "(1d1)d(2d8)" do
      subject = %Builder{
        quantity: nil,
        quantity_expression: %Expression{
          d: :d,
          multiplier: nil,
          quantity: 1,
          raw: "1d1*2",
          sides: 1
        },
        raw: "(1d1)d(2d8)",
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

      expected = Builder.distribute(subject)
      assert Enum.member?(2..16, expected.sides)
      assert is_nil(expected.quantity_expression)
      assert is_nil(expected.sides_expression)
      assert 1 = expected.quantity
    end

    test "(1d1*2)d(2d8)" do
      subject = %Builder{
        quantity: nil,
        quantity_expression: %Expression{
          d: :d,
          multiplier: 2,
          quantity: 1,
          raw: "1d1*2",
          sides: 1
        },
        raw: "(1d1*2)d(2d8)",
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

      expected = Builder.distribute(subject)
      assert Enum.member?(2..16, expected.sides)
      assert is_nil(expected.quantity_expression)
      assert is_nil(expected.sides_expression)
      assert 2 = expected.quantity
    end
  end
end
