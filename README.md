# Dice

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bot, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bot>.


```elixir
alias Dice.{Die, Parser, Expression, Builder, Rollable, Roller, Modifier, Tray, Grammar}

Roller.roll("{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}") |> Enum.map(&(&1.total))
[15, 14, 14, 11, 9, 11]
```
