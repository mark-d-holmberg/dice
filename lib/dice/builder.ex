defmodule Dice.Builder do
  @moduledoc """
  For building complex expressions
  """

  # What kinds of grammar we respond to
  @valid_kinds [:multiplier, :simple, :only_sides, :flat_value]

  use Dice.Matching, filters: @valid_kinds

  @typedoc "Types of Builder setups."
  @type builder_type :: :simple | :complex

  use Dice.ContextClient

  defstruct type: nil,
            quantity_expression: nil,
            sides_expression: nil,
            quantity: nil,
            sides: nil,
            raw: nil

  @typedoc "Represents trying to build a Complex expression"
  @type t :: %__MODULE__{
          type: builder_type(),
          quantity_expression: Expression.t() | nil,
          sides_expression: Expression.t() | nil,
          quantity: integer() | nil,
          sides: integer() | nil,
          raw: String.t()
        }

  # Convenience method
  @spec guess(String.t()) :: {:ok, Expression.t()} | {:ok, Builder.t()}
  def guess({:ok, %Rollable{raw: raw} = _r}), do: guess(raw)

  @doc """
  Take a wild guess as to what kind of structure we should return.
  """
  def guess(raw) when binary_present(raw) do
    with {regex, kind} when kind in @valid_kinds <- matching?(raw) do
      case kind do
        # "10"
        :flat_value ->
          with %{"flat_value" => flat_value} <- Regex.named_captures(regex, raw) do
            Expression.build(%{
              d: :d,
              flat_value: String.to_integer(flat_value),
              multiplier: nil,
              raw: raw
            })
          end

        # 1d4*2
        :multiplier ->
          with %{"quantity" => reg_quantity, "sides" => reg_sides, "multiplier" => reg_multi} <-
                 Regex.named_captures(regex, raw) do
            Expression.build(%{
              d: :d,
              multiplier: String.to_integer(reg_multi),
              raw: raw,
              quantity: String.to_integer(reg_quantity),
              sides: String.to_integer(reg_sides)
            })
          end

        :simple ->
          # "1d4", "2d20", "20d20"
          with %{"quantity" => reg_quantity, "sides" => reg_sides} <-
                 Regex.named_captures(regex, raw) do
            Expression.build(%{
              d: :d,
              multiplier: nil,
              raw: raw,
              quantity: String.to_integer(reg_quantity),
              sides: String.to_integer(reg_sides)
            })
          end

        :only_sides ->
          with %{"sides" => reg_sides} <- Regex.named_captures(regex, raw) do
            # "d20"
            # quantity is assumed as 1
            Expression.build(%{
              d: :d,
              multiplier: nil,
              raw: raw,
              quantity: 1,
              sides: String.to_integer(reg_sides)
            })
          end
      end
    else
      _complex ->
        # Complex
        {:ok,
         %__MODULE__{
           type: :complex,
           raw: raw,
           quantity_expression: %Expression{raw: ""},
           sides_expression: %Expression{raw: ""}
         }}
    end
  end

  # Convenience method
  @spec distribute({:ok, Builder.t()} | {:ok, Rollable.t()} | Expression.t() | Builder.t()) ::
          Builder.t()
  def distribute({:ok, %__MODULE__{} = b}), do: distribute(b)

  # Convenience method
  def distribute({:ok, %Rollable{expressable: expressable}}), do: distribute(expressable)

  # Both sides are expressions
  # "(1d4)d(2d10)"
  @doc """
  Distribute the given `%Builder{}` struct to prepare it for conversion into an `%Expression{}`
  """
  def distribute(
        %__MODULE__{
          quantity: nil,
          sides: nil,
          sides_expression: %Expression{} = se,
          quantity_expression: %Expression{}
        } = b
      ) do
    %{b | sides: determine_rolls(se), sides_expression: nil}
    |> distribute()
  end

  # Sides is an expression, quantity_expression is nil
  def distribute(%__MODULE__{sides_expression: %Expression{} = se, quantity_expression: nil} = b) do
    %{b | sides: determine_rolls(se), sides_expression: nil}
  end

  # Distribute twice
  # Sides is an expression, quantity_expression is not nil
  def distribute(
        %__MODULE__{sides_expression: %Expression{}, quantity_expression: %Expression{}} = b
      ) do
    %{b | quantity_expression: nil}
    |> distribute()
    |> distribute()
  end

  # NOTE: Transformations to the value happen after we roll!
  # Quantity is an expression, sides_expression is nil
  def distribute(
        %__MODULE__{quantity: _q, sides_expression: nil, quantity_expression: %Expression{} = qe} =
          b
      ) do
    # Don't pass it forward
    quantity_number_rolled = determine_rolls(%{qe | multiplier: nil})

    %{
      b
      | quantity: determine_multiplier(quantity_number_rolled, Map.get(qe, :multiplier)),
        quantity_expression: nil
    }
  end

  # Distribute Twice
  def distribute(
        %__MODULE__{
          quantity: _q,
          sides_expression: %Expression{},
          quantity_expression: %Expression{}
        } = b
      ) do
    %{b | sides_expression: nil}
    |> distribute()
    |> distribute()
  end

  # Roll for either the Quantity Expression, Sides Expression, or Both
  defp determine_rolls(%Expression{} = exp) do
    with [rolls: %Tray{items: items}] <- Roller.roll(exp) do
      items
      |> Enum.reduce(0, fn %Die{rolled: rolled}, acc -> acc + rolled end)
    end
  end

  # No multiplier present
  defp determine_multiplier(total, nil) when is_integer(total), do: total

  # Multiplier Present
  # "(1d20*2)d10"
  defp determine_multiplier(total, multiplier)
       when is_integer(total) and is_integer(multiplier) do
    total * multiplier
  end
end
