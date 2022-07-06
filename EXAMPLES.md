### EXAMPLES

```elixir
samples = ["1d4", "2d10", "12d4", "12d10", "(1d4)", "(2d10)", "(12d4)", "(12d10)", "1d(1d4)", "2d(10d4)", "4d(1d12)", "6d(10d4)", "(1d4)d10", "10d(1d4)", "(1d4)d(1d20)"]

alias Dice.Parser

samples |> Enum.map(fn x -> {x, Parser.parse(x)} end)

[
  {"1d4",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "1d4",
      quantity: 1,
      sides: 4
    }}},
  {"2d10",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "2d10",
      quantity: 2,
      sides: 10
    }}},
  {"12d4",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "12d4",
      quantity: 12,
      sides: 4
    }}},
  {"12d10",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "12d10",
      quantity: 12,
      sides: 10
    }}},
  {"(1d4)",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "(1d4)",
      quantity: 1,
      sides: 4
    }}},
  {"(2d10)",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "(2d10)",
      quantity: 2,
      sides: 10
    }}},
  {"(12d4)",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "(12d4)",
      quantity: 12,
      sides: 4
    }}},
  {"(12d10)",
   {:ok,
    %Dice.Expression{
      d: :d,
      multiplier: nil,
      raw: "(12d10)",
      quantity: 12,
      sides: 10
    }}},
  {"1d(1d4)",
   {:ok,
    %Dice.Builder{
      quantity: 1,
      quantity_expression: nil,
      raw: "1d(1d4)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d4",
        quantity: 1,
        sides: 4
      },
      type: :complex
    }}},
  {"2d(10d4)",
   {:ok,
    %Dice.Builder{
      quantity: 2,
      quantity_expression: nil,
      raw: "2d(10d4)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "10d4",
        quantity: 10,
        sides: 4
      },
      type: :complex
    }}},
  {"4d(1d12)",
   {:ok,
    %Dice.Builder{
      quantity: 4,
      quantity_expression: nil,
      raw: "4d(1d12)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d12",
        quantity: 1,
        sides: 12
      },
      type: :complex
    }}},
  {"6d(10d4)",
   {:ok,
    %Dice.Builder{
      quantity: 6,
      quantity_expression: nil,
      raw: "6d(10d4)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "10d4",
        quantity: 10,
        sides: 4
      },
      type: :complex
    }}},
  {"(1d4)d10",
   {:ok,
    %Dice.Builder{
      quantity: nil,
      quantity_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d4",
        quantity: 1,
        sides: 4
      },
      raw: "(1d4)d10",
      sides: 10,
      sides_expression: nil,
      type: :complex
    }}},
  {"10d(1d4)",
   {:ok,
    %Dice.Builder{
      quantity: 10,
      quantity_expression: nil,
      raw: "10d(1d4)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d4",
        quantity: 1,
        sides: 4
      },
      type: :complex
    }}},
  {"(1d4)d(1d20)",
   {:ok,
    %Dice.Builder{
      quantity: nil,
      quantity_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d4",
        quantity: 1,
        sides: 4
      },
      raw: "(1d4)d(1d20)",
      sides: nil,
      sides_expression: %Dice.Expression{
        d: :d,
        multiplier: nil,
        raw: "1d20",
        quantity: 1,
        sides: 20
      },
      type: :complex
    }}}
]
