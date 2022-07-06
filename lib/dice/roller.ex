defmodule Dice.Roller do
  @moduledoc """
  A polyhedral dice roller
  """
  use Dice.ContextClient

  @typedoc "That which can be rolled"
  @type rollable_types ::
          String.t() | {:ok, Expression.t()} | Expression.t() | Rollable.t() | [Rollable.t()]

  @typedoc "That which can be returned from rolling"
  @type returnable_types :: Result.t() | list() | {:error, String.t()}

  @doc """
  Roll the specified number of dice
  """
  @spec roll(rollable_types()) :: returnable_types()
  def roll(raw) when binary_present(raw) do
    case Parser.parse(raw) do
      # A list of Rollables with a single Modifier (Braces with outer Modifier)
      # "{2d10, 3d8kl2, 12d6kh3}kh2"
      {:ok, [%Rollable{} | _rest] = rollables, %Modifier{} = mod} ->
        rollables
        |> roll()
        |> apply_modifiers(%Rollable{modifiers: [mod]})

      # NOTE: The clause order matters!
      # "1d(1d20)"
      # "(1d20*2)d(1d10)"
      # "(2d4)d8"
      # "10d(2d10)kh2"
      {:ok,
       %Rollable{
         expressable: %Builder{} = b,
         modifiers: mods
       } = r} ->
        with %Builder{} = builder <- Builder.distribute(b),
             {:ok, %Expression{} = expr} <- Expression.from_builder(builder) do
          case mods do
            [] ->
              calculate_expression(expr)

            other when is_list(other) ->
              # NOTE: we could simplify this even further by DRYing up calculate_expression_with_modifiers/2
              calculate_expression_with_modifiers(expr, r)
          end
        end

      # "2d8"
      # "2d6kh"
      # Rollable with an Expression for the expressable, with or without modifiers
      {:ok, %Rollable{expressable: %Expression{}} = r} ->
        roll(r)

      # A straight list of rollables
      # "{2d4, 3d8}"
      [%Rollable{} | _rest] = rollables ->
        roll(rollables)

      other ->
        {:error, "Roller.roll - Unmatched case: '#{inspect(other)}'", :unmatched_case}
    end
  end

  def roll(%Rollable{expressable: %Expression{} = expr, modifiers: modifiers} = r) do
    case modifiers do
      no_mods when no_mods in [nil, []] -> calculate_expression(expr)
      [_has_mods | _] -> calculate_expression_with_modifiers(expr, r)
    end
  end

  def roll([%Rollable{} | _rest] = rollables) do
    rollables
    |> Enum.map(&roll(&1))
  end

  # Just pass it forward
  def roll({:ok, %Expression{} = expr}), do: roll(expr)

  # "3d12ms>(20)"
  # Just a straight flat value
  def roll(%Expression{flat_value: flat_value, quantity: nil, sides: nil})
      when is_integer(flat_value) do
    with {:ok, %Tray{} = tray} = Tray.build("expression", [%Die{faces: nil, rolled: flat_value}]) do
      [rolls: tray]
    end
  end

  # Roll when given an %Expression{} struct
  def roll(%Expression{quantity: quantity, sides: sides})
      when is_integer(quantity) and is_integer(sides) do
    rolls =
      Enum.map(1..quantity, fn _x ->
        with {:ok, die} <- Die.build(sides) do
          die
        end
      end)
      |> Enum.reduce([], fn dice, acc ->
        acc ++ [%{dice | rolled: perform_roll(1, dice.faces)}]
      end)
      |> Enum.sort()

    with {:ok, %Tray{} = tray} = Tray.build("expression", rolls) do
      [rolls: tray]
    end
  end

  # No modifiers to apply
  defp apply_modifiers(rolls, %Rollable{modifiers: []}), do: rolls

  # Apply the first modifier to this list of rolls
  defp apply_modifiers(rolls, %Rollable{modifiers: [%Modifier{} = mod | _rest]})
       when is_list(rolls) do
    # :count_success, :margin_success, :kh, :kl
    Modifier.apply_modifier(mod, rolls)
  end

  # Calculate the rolls given the expression
  defp calculate_expression(%Expression{} = expression) do
    with [rolls: %Tray{items: items} = tray] <- roll(expression) do
      total = Enum.reduce(items, 0, fn %Die{rolled: rolled}, acc -> acc + rolled end)
      %Result{expression: expression, rolls: tray, total: total}
    end
  end

  # Calculate the rolls given the expression and modifiers
  defp calculate_expression_with_modifiers(%Expression{} = expression, %Rollable{} = r) do
    # TODO: this is where you've messed it all up
    with rolled_result <- calculate_expression(expression),
         %Tray{items: items} <- Map.get(rolled_result, :rolls) do
      kept_rolls = apply_modifiers(items, r)

      margin_dc_dice = Enum.filter(kept_rolls, fn dice -> is_nil(dice.faces) end)

      kept_rolls = Enum.reject(kept_rolls, fn dice -> is_nil(dice.faces) end)

      total = Enum.sum(Enum.map(kept_rolls, fn dice -> dice.rolled end))

      margin_of_success =
        case margin_dc_dice do
          [%Die{faces: nil, rolled: dc_rolled}] when is_integer(dc_rolled) ->
            IO.puts("Margin of Success DC rolled value of: '#{dc_rolled}'")
            total - dc_rolled

          _other ->
            nil
        end

      with {:ok, %Tray{} = kept_rolls_tray} <- Tray.build("kept_rolls", kept_rolls) do
        # With modifiers
        %Result{
          margin_dc_dice: margin_dc_dice,
          margin_of_success: margin_of_success,
          expression: expression,
          rolls: items,
          kept_rolls: kept_rolls_tray,
          total: total,
          modifiers: Map.get(r, :modifiers)
        }
      else
        _other -> :error
      end
    end
  end

  # Handle the actual rolling
  defp perform_roll(min, max) when is_integer(min) and is_integer(max) do
    Enum.random(min..max)
  end
end
