defmodule Dice.Parser do
  @moduledoc """
  Parse a properly formatted dice rolling string expression
  """
  use Dice.ContextClient

  @doc """
  Parse a given string expression to see if it is valid syntax
  """
  @spec parse(String.t() | Rollable.t()) ::
          {:ok, Rollable.t()}
          | {:ok, list(Rollable.t()), Modifier.t()}
          | list(Rollable.t())
          | {:error, String.t()}
  def parse(%Rollable{raw: raw, modifiers: nil} = rollable) when binary_present(raw) do
    parse(%{rollable | modifiers: []})
  end

  def parse(%Rollable{raw: raw, modifiers: []} = rollable) when binary_present(raw) do
    case Complex.matching?(raw) do
      # Braces
      {regex, kind}
      when kind in [:count_success, :braces_with_maybe_modifier, :braces_no_outer_modifiers] ->
        Braces.handle_braces({regex, kind}, raw)

      _not_braces ->
        # Have to parse brace expressions before modifiers are parsed
        with {:ok, %Modifier{raw: without_mods} = mod} <- Modifier.scan(raw) do
          # This section deals exclusively with modifiers like 'kh' and 'kl'

          # Not passing it forward yet
          rollable = Rollable.add_modifier(rollable, mod)

          # We're only passing in the clean stuff!
          # (1d1*2)d(2d8)
          {:ok, guess(%{rollable | raw: without_mods})}
        else
          # no 'kh' or 'kl' modifiers in the string
          {:no_modifiers, _} ->
            {:ok, guess(rollable)}
        end
    end
  end

  # When it's a string
  def parse(raw) when binary_present(raw) do
    with {:ok, %Rollable{} = rollable} <- Rollable.build(raw) do
      parse(rollable)
    end
  end

  defp guess(%Rollable{raw: raw} = r) do
    case Builder.guess(raw) do
      # "d4", "1d4", "20d20"
      {:ok, %Expression{quantity: q, sides: s} = exp} when is_integer(q) and is_integer(s) ->
        %{r | expressable: exp}

      {:ok, %Expression{flat_value: flat_value} = exp} when is_integer(flat_value) ->
        %{r | expressable: exp}

      # It wasn't a simple die we can parse
      {:ok, %Builder{type: :complex} = builder} ->
        with {:ok, expressable} <- Complex.process_complex(builder) do
          %{r | expressable: expressable}
        end

      other ->
        {:error, other, "Can't guess"}
    end
  end
end
