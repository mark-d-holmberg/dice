# use Dice.Matching
defmodule Dice.Matching do
  @moduledoc """
  Matching regex cases and filtering
  """

  @context_functions ~w(matching?)a

  defmacro __using__(opts \\ []) do
    opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))

    quote do
      # How to filter the list of regex for the 'using' module
      @filters Keyword.get(unquote(opts), :filters, [])

      unquote(generate_methods(opts))
    end
  end

  defp generate_methods(opts) do
    only = Keyword.get(opts, :only, @context_functions)
    except = Keyword.get(opts, :except, [])

    for method <- @context_functions, method in only && method not in except do
      gen(method, opts)
    end
  end

  # Matching?
  defp gen(:matching?, _opts) do
    quote location: :keep do
      @doc ~s"""
      Filter out the list of Regex results from Grammar
      """
      @spec matching?(String.t()) :: {Regex.t(), atom()} | nil
      def matching?(str) do
        case Dice.Grammar.matching?(str, @filters) do
          [] -> nil
          items when is_list(items) -> List.first(items)
        end
      end
    end
  end
end
