defmodule Dice.Tray do
  @moduledoc """
  Represents a tray of rolled %Die{} items
  """
  use Dice.ContextClient

  defstruct kind: nil, items: nil

  @typedoc "Builds a Tray struct to represent a list of rolled dice"
  @type t :: %__MODULE__{
          kind: String.t(),
          items: [Die.t()]
        }

  @doc """
  Build a new struct which represents a list of rolled %Die{} items

  ## Examples
      iex> Tray.build("kept", [])
      {:ok, %Dice.Tray{kind: "kept", items: []}}
  """
  @spec build(String.t(), list()) :: {:ok, t()}
  def build(kind, items \\ []) when binary_present(kind) and is_list(items) do
    {:ok, struct(__MODULE__, kind: kind, items: items)}
  end
end
