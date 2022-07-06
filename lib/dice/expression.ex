defmodule Dice.Expression do
  @moduledoc """
  A struct to represent a dice expression string
  """
  use Dice.ContextClient

  defstruct raw: nil, quantity: nil, sides: nil, d: nil, multiplier: nil, flat_value: nil

  @typedoc "Represents the simplest dice expression which can be evaluated"
  @type t :: %__MODULE__{
          raw: String.t(),
          flat_value: integer() | nil,
          quantity: integer() | nil,
          sides: integer() | nil,
          d: atom(),
          multiplier: integer() | nil
        }

  use Dice.Buildable,
    model: Dice.Expression,
    except: [:__before_build__, :__after_build__],
    valid_attrs: [
      :raw,
      :quantity,
      :sides,
      :d,
      :multiplier,
      :flat_value
    ]

  @doc """
  Builds a new Expression, which represents the most basic evaluation of a string expression.

  ## Examples
      iex> Expression.build(%{d: :d, flat_value: 10, multiplier: nil, raw: "10"})
      {:ok, %Expression{d: :d, multiplier: nil, quantity: nil, raw: "10", sides: nil, flat_value: 10 }}

      iex> Expression.build("1d4")
      {:ok,
       %Rollable{
         expressable: %Expression{
           d: :d,
           flat_value: nil,
           multiplier: nil,
           quantity: 1,
           raw: "1d4",
           sides: 4
         },
         modifiers: [],
         raw: "1d4"
       }}

      iex> Expression.build("1d4*2")
      {:ok,
       %Rollable{
         expressable: %Expression{
           d: :d,
           flat_value: nil,
           multiplier: 2,
           quantity: 1,
           raw: "1d4*2",
           sides: 4
         },
         modifiers: [],
         raw: "1d4*2"
       }}
  """
  @spec build(String.t()) :: {:ok, Rollable.t()}
  def build(raw) when binary_present(raw) do
    Parser.parse(raw)
  end

  @doc """
  Builds an new struct from a `%Builder{}` struct.
  """
  @spec from_builder(Builder.t()) :: {:ok, t()}
  def from_builder(%Builder{sides: sides, quantity: quantity}) do
    {:ok,
     %__MODULE__{
       sides: sides,
       quantity: quantity,
       d: :d,
       raw: "#{quantity}d#{sides}"
     }}
  end

  defp __before_build__(%{} = map_with_atom_keys), do: map_with_atom_keys
  defp __after_build__({:ok, %__MODULE__{}} = result), do: result
end
