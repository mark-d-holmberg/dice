defmodule Dice.Result do
  @moduledoc """
  The complete result of evaluating the expression
  """
  use Dice.ContextClient

  defstruct expression: nil,
            rolls: nil,
            kept_rolls: nil,
            total: nil,
            modifiers: nil,
            margin_dc_dice: nil,
            margin_of_success: nil

  @typedoc "Represents the final Result of evaluating and processing a roll expression"
  @type t :: %__MODULE__{
          expression: integer() | any,
          rolls: list() | Tray.t(),
          kept_rolls: list(),
          total: integer(),
          modifiers: list(),
          margin_dc_dice: list(),
          margin_of_success: integer()
        }

  @doc """
  Build a new struct

  ## Examples
      iex> Result.build(%{})
      {:ok, %Dice.Result{}}
  """
  @spec build(map()) :: {:ok, t()}
  def build(map) when is_map(map) do
    {:ok, struct(__MODULE__, map)}
  end
end
