defmodule Dice.Grammar do
  @moduledoc """
  Represents a 'Grammar' for parsing Dice Expressions
  """
  use Dice.ContextClient

  # Modifier

  # [
  #   :margin_success,
  #   :keep_amount,
  #   :count_succes
  # ]

  # "2d20kh"
  @keep_regex ~r/\{?(?<expression>.+?)\}?(?<modifier>(kh|kl))(?<take>\d+)?/

  # "{1d4, 3d8}cs>5"
  # @count_success_optional_braces_regex ~r/\{?(?<expression>.+[^\}])\}?(?<modifier>(cs))(?<operator>>|>=|<=|<|=)?(?<take>\d+)/

  # "{1d4, 3d8}ms>(2d8)"
  @margin_success_regex ~r/\{?(?<expression>.+[^\}])\}?(?<modifier>(ms))(?<operator>>|>=|<=|<|=)(?<take>.+)/

  # Wild Dice:
  @wild_dice_regex ~r/^(?<expression>1d(\d+))(?<modifier>x)$/

  # Builder

  # [
  #   :multiplier,
  #   :simple,
  #   :only_sides,
  #   :flat_value
  # ]

  # "1"
  @flat_value_regex ~r/^\(?(?<flat_value>\d+)\)?$/

  # "1d4"
  @simple_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\)?$/

  # "d20"
  @only_sides_regex ~r/^d(?<sides>\d+)\)?$/

  # "(1d20*2)"
  @multiplier_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\*(?<multiplier>\d+)\)?$/

  # Parser

  # [
  #   :count_success,
  #   :complex_quantity_multiplier,
  #   :complex,
  #   :starts_with,
  #   :ends_with,
  #   :complex_multiplier_ends_with,
  #   :braces_with_maybe_modifier_regex,
  #   :braces_no_outer_modifiers
  # ]

  # Complex::

  # NOTE: Fairly certain the the "cs" part has to be outside the braces as per this regex
  # {6d6, 5d8, 4d10, 3d12}cs>15
  # {2d10, 4d8kh2, 20d6kh3}cs<15
  # {2d10, 4d8kh2, 20d6kh3}cs<=15
  # {2d10, 4d8kh2, 20d6kh3}cs>=15
  # {2d10, 4d8kh2, 20d6kh3}cs=15
  @count_success_required_braces ~r/{(?<expression>.+)}(?<modifier>cs)?(?<operator>>|>=|<=|<|=)?(?<take>\d+)$/

  # {4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}
  @braces_no_outer_modifiers ~r/{(?<expression>.+)}$/

  # NOTE: conflicts with @keep_regex
  # "{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}"
  @braces_with_maybe_modifier_regex ~r/{(?<expression>.+)}(?<modifier>kh|kl)(?<take>[^>|>=|<=|<|=]?\d*?$)/

  # "(1d20*2)d(1d10)"
  @complex_quantity_multiplier_regex ~r/^\(?(?<first_die>\d+d\d+\*(?<multiplier>\d+))\)?d\(?(?<second_die>\d+d\d+)\)?$/

  # "(1d20*2)d20"
  @complex_multiplier_ends_with ~r/^\(?(?<first_die>\d+d\d+\*(?<multiplier>\d+))\)(?<ends_with>d\d+)$/

  # "(1d4)d(1d20)"
  @complex_regex ~r/^\(?(?<first_die>\d+d\d+)\)?d\(?(?<second_die>\d+d\d+)\)?$/

  # "(1d4)d20"
  @starts_with ~r/^\((?<first_die>\d+d\d+)\)(?<ends_with>d.*)$/

  # "6d(2d12)"
  @ends_with ~r/^(?<quantity>\d+)d\((?<second_die>\d+d\d+)\)$/

  # "1d1+5"
  @roll_modifier_addition_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\+(?<addition>\d+)\)?$/

  # "1d1-5"
  @roll_modifier_subtraction_regex ~r/^\(?(?<quantity>\d+)d(?<sides>\d+)\-(?<subtraction>\d+)\)?$/

  # NOTE: these are in a specific order!
  @doc """
  All the patterns the Grammar knows
  """
  @spec all_patterns() :: list({Regex.t(), atom()})
  def all_patterns() do
    [
      {@margin_success_regex, :margin_success},
      {@count_success_required_braces, :count_success},
      {@wild_dice_regex, :wild_dice},

      # These two conflict
      {@braces_no_outer_modifiers, :braces_no_outer_modifiers},
      {@braces_with_maybe_modifier_regex, :braces_with_maybe_modifier},
      {@keep_regex, :keep_amount},
      {@multiplier_regex, :multiplier},
      {@simple_regex, :simple},
      {@only_sides_regex, :only_sides},
      {@flat_value_regex, :flat_value},
      {@complex_quantity_multiplier_regex, :complex_quantity_multiplier},
      {@complex_multiplier_ends_with, :complex_multiplier_ends_with},
      {@complex_regex, :complex},
      {@starts_with, :starts_with},
      {@ends_with, :ends_with},
      {@roll_modifier_addition_regex, :roll_modifier_addition},
      {@roll_modifier_subtraction_regex, :roll_modifier_subtraction}
    ]
  end

  @doc """
  Does this string match any known pattern stored in the Grammar?
  """
  @spec matching?(String.t(), list()) :: list({Regex.t(), atom()}) | list()
  def matching?(raw, filters \\ []) when binary_present(raw) do
    all_patterns()
    |> Enum.filter(fn {_regex, kind} ->
      # Any empty list means don't filter at all
      case filters do
        [] -> true
        _other -> Enum.member?(filters, kind)
      end
    end)
    |> Task.async_stream(
      fn {regex, kind} ->
        with true <- Regex.match?(regex, raw) do
          {regex, kind}
        end
      end,
      max_concurrency: 3
    )
    |> Enum.filter(&match?({:ok, {_regex, _kind}}, &1))
    |> Enum.reduce([], fn {:ok, {regex, kind}}, acc -> [{regex, kind} | acc] end)
    |> Enum.reverse()
  end
end
