defmodule Dice.Modifier do
  @moduledoc """
  Represents a modifier to a dice roll expression
  """
  use Dice.ContextClient

  @valid_kinds [
    :count_success,
    :keep_amount,
    :margin_success,
    :wild_dice,
    :roll_modifier_addition,
    :roll_modifier_subtraction
  ]

  use Dice.Matching, filters: @valid_kinds

  @typedoc "What kind of modifier this struct is"
  @type modifier_kind ::
          :keep_highest
          | :keep_lowest
          | :count_success
          | :wild_dice
          | :roll_modifier_addition
          | :roll_modifier_subtraction

  defstruct kind: nil, raw: nil, take: nil, operator: nil

  @typedoc "Represents a modifier to the Rollable"
  @type t :: %__MODULE__{
          kind: modifier_kind(),
          raw: String.t(),
          take: integer() | Rollable.t() | nil,
          operator: String.t()
        }

  @doc """
  Scan a string to see if it contains modifiers

  ## Examples

      iex> Modifier.scan("2d20kh")
      {:ok, %Modifier{kind: :keep_highest, raw: "2d20", take: 1}}

      iex> Modifier.scan("2d20kl")
      {:ok, %Modifier{kind: :keep_lowest, raw: "2d20", take: 1}}

      iex> Modifier.scan("{2d10kh2}")
      {:ok, %Dice.Modifier{kind: :keep_highest, raw: "2d10", take: 2}}

      iex> Modifier.scan("{4d10}kl2")
      {:ok, %Dice.Modifier{kind: :keep_lowest, raw: "4d10", take: 2}}

  """
  @spec scan(String.t()) :: {:ok, t()} | {:no_modifiers, String.t()}
  def scan(raw) when binary_present(raw) do
    with {regex, kind} when kind in @valid_kinds <- matching?(raw) do
      case kind do
        :keep_amount ->
          with %{"expression" => expression, "modifier" => mod, "take" => take} <-
                 Regex.named_captures(regex, raw) do
            {:ok,
             %__MODULE__{
               kind: determine_kind(mod),
               raw: expression,
               take: if(match?("", take), do: 1, else: String.to_integer(take))
             }}
          end

        :count_success ->
          with %{
                 "expression" => expression,
                 "modifier" => mod,
                 "operator" => operator,
                 "take" => take
               }
               when mod != "" <- Regex.named_captures(regex, raw) do
            {:ok,
             %__MODULE__{
               kind: determine_kind(mod),
               raw: expression,
               take: String.to_integer(take),
               operator: operator
             }}
          end

        :margin_success ->
          # 3d12ms>(4d6)
          # {3d12, 2d10, 4d12}ms>(4d6)
          # 3d12ms>({4d6, 3d12}kh)
          # 3d12ms>{4d6, 3d12}kh
          with %{
                 "expression" => expression,
                 "modifier" => mod,
                 "operator" => operator,
                 "take" => take
               } <- Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{}} = take_rollable} <-
                 Parser.parse(take) do
            {:ok,
             %__MODULE__{
               kind: determine_kind(mod),
               raw: expression,
               take: take_rollable,
               operator: operator
             }}
          end

        :wild_dice ->
          with %{
                 "expression" => expression,
                 "modifier" => mod
               } <- Regex.named_captures(regex, raw) do
            {:ok,
             %__MODULE__{
               kind: determine_kind(mod),
               raw: expression,
               take: nil,
               operator: nil
             }}
          end

        :roll_modifier_addition ->
          with %{"addition" => add_number} <-
                 Regex.named_captures(regex, raw) do
            {:ok,
             %__MODULE__{
               kind: :roll_modifier_addition,
               raw: raw,
               take: String.to_integer(add_number),
               operator: nil
             }}
          end

        :roll_modifier_subtraction ->
          with %{"subtraction" => subtract_number} <-
                 Regex.named_captures(regex, raw) do
            {:ok,
             %__MODULE__{
               kind: :roll_modifier_subtraction,
               raw: raw,
               take: String.to_integer("-#{subtract_number}"),
               operator: nil
             }}
          end
      end
    else
      nil -> {:no_modifiers, raw}
    end
  end

  @doc """
  Apply the specified Modifier to a list of Rolls
  """

  # :keep_highest
  @spec apply_modifier(Modifier.t(), list()) :: list() | {:error, String.t()}
  def apply_modifier(%Modifier{kind: :keep_highest, take: take}, rolls) when is_list(rolls) do
    rolls
    |> Enum.sort(:desc)
    |> Enum.take(take)
  end

  # :keep_lowest
  def apply_modifier(%Modifier{kind: :keep_lowest, take: take}, rolls) when is_list(rolls) do
    rolls
    |> Enum.sort(:asc)
    |> Enum.take(take)
  end

  # "{1d4, 2d8, 3d6}cs>2d4" Will match with a take of 2
  # NOTE: The 'take' is meant to be a flat value like '10'
  # NOTE: "{1d4, 2d8, 3d6}cs>(2d4)" does NOT match!
  # :count_success
  def apply_modifier(%Modifier{kind: :count_success, take: take, operator: operator}, rolls)
      when is_list(rolls) do
    rolls
    |> Enum.filter(fn x ->
      case operator do
        "<" -> x.total < take
        "<=" -> x.total <= take
        "=" -> x.total == take
        ">=" -> x.total >= take
        ">" -> x.total > take
      end
    end)
  end

  # :margin_success
  def apply_modifier(
        %Modifier{kind: :margin_success, take: %Rollable{} = take_rollable, operator: _operator},
        rolls
      )
      when is_list(rolls) do
    # NOTE: this ain't right yet.

    # Get the margin of success based on an opposed roll of 4d6.
    # This modifier subtracts a target value set by the user from the result of the dice rolled, and returns the difference
    # as the final total. If the amount rolled is less than the target it outputs a negative number, and a positive number
    # if there is a remainder after the subtraction.
    # /roll 3d12ms>(4d6)

    # Got roll the right side value first
    with %Result{total: target_value, rolls: _rolls} <- Roller.roll(take_rollable) do
      # _rolls is the tray for a flat value
      [%Die{rolled: target_value, faces: nil} | rolls]
    else
      other ->
        {:error, "Failed to roll Margin of Success Modifier: result was: '#{inspect(other)}'"}
    end
  end

  # :wild_dice
  def apply_modifier(%Modifier{kind: :wild_dice, raw: mod_raw, take: nil, operator: nil}, rolls)
      when is_list(rolls) do
    # Roll an additional die if this one rolled the max
    [%Die{faces: faces, rolled: rolled}] = rolls

    if(faces == rolled) do
      with %Result{rolls: %Tray{items: [wild_die]}} <- Roller.roll(mod_raw) do
        [wild_die | rolls]
      end
    else
      rolls
    end
  end

  # "1d1-5"
  # :roll_modifier_subtraction
  def apply_modifier(
        %Modifier{kind: :roll_modifier_subtraction, raw: _mod_raw, take: take, operator: nil},
        rolls
      )
      when is_list(rolls) do
    [%Die{rolled: take, faces: 1} | rolls]
  end

  # "1d1+5"
  # :roll_modifier_addition
  def apply_modifier(
        %Modifier{kind: :roll_modifier_addition, raw: _mod_raw, take: take, operator: nil},
        rolls
      )
      when is_list(rolls) do
    [%Die{rolled: take, faces: 1} | rolls]
  end

  # fallback
  def apply_modifier(_, rolls) when is_list(rolls) do
    rolls
  end

  # What kind of thing are you?
  defp determine_kind(mod) when binary_present(mod) do
    case String.downcase(mod) do
      "kh" -> :keep_highest
      "kl" -> :keep_lowest
      "cs" -> :count_success
      "ms" -> :margin_success
      "x" -> :wild_dice
    end
  end
end
