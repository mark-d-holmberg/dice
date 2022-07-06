defmodule Dice.ContextClient do
  @moduledoc """
  Makes using Dice contexts easy. Aliases the majority of things needed.
  """
  defmacro __using__(_) do
    quote do
      import Dice.CustomGuards

      alias Dice.{
        Braces,
        Builder,
        Complex,
        Die,
        Expression,
        Grammar,
        Modifier,
        Parser,
        Result,
        Rollable,
        Roller,
        Tray
      }
    end
  end
end
