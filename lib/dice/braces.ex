defmodule Dice.Braces do
  @moduledoc """
  A module for parsing the Braces from a dice string expression
  """
  use Dice.ContextClient

  @valid_kinds ~w(count_success braces_with_maybe_modifier braces_no_outer_modifiers)a

  # Async parsing of braces
  @doc """
  Take a string and convert it into a Task to process later
  """
  @spec expressions_from_braces(String.t()) :: Task.t()
  def expressions_from_braces(braces_string) when binary_present(braces_string) do
    Task.async(fn ->
      braces_string
      |> String.split(", ")
      |> Enum.map(&String.trim(&1, " "))
      |> Enum.map(fn single_dice_string ->
        with {:ok, result} <- Parser.parse(single_dice_string) do
          result
        end
      end)
    end)
  end

  @doc """
  Handles the processing of Braces expressions
  """
  @spec handle_braces({Regex.t(), atom()}, String.t()) ::
          list(Rollable.t())
          | {:ok, list(Rollable.t()), Modifier.t()}
          | {:error, String.t()}
  def handle_braces({regex, kind} = tuple, raw)
      when binary_present(raw) and kind in @valid_kinds do
    case tuple do
      {_, :count_success} ->
        # NOTE: Literally the same as braces with an outer modifier
        # "{6d6, 5d8, 4d10, 3d12}cs>15"
        case Regex.named_captures(regex, raw) do
          %{
            "expression" => braces_string,
            "modifier" => _modifier,
            "operator" => _operator,
            "take" => _take
          } ->
            with %Task{} = task <- expressions_from_braces(braces_string),
                 [%Rollable{} | _rest] = expressions <- Task.await(task),
                 {:ok, %Modifier{} = modifier} <- Modifier.scan(raw) do
              {:ok, expressions, modifier}
            else
              other -> {:error, inspect(other)}
            end
        end

      {_, :braces_no_outer_modifiers} ->
        case Regex.named_captures(regex, raw) do
          %{"expression" => braces_string} ->
            # "2d10, 4d8kh2, 20d6kh3"
            with %Task{} = task <- expressions_from_braces(braces_string),
                 [%Rollable{} | _rest] = expressions <- Task.await(task) do
              expressions
            else
              other -> {:error, inspect(other)}
            end
        end

      {_, :braces_with_maybe_modifier} ->
        case Regex.named_captures(regex, raw) do
          %{
            "expression" => braces_string,
            "modifier" => _mod,
            "take" => _take
          } ->
            # NOTE: literally the same logic as :count_success
            # iex(13)> Parser.parse("{2d10, 4d8kh2, 20d6kh3}kh")
            # iex(13)> Parser.parse("{2d10, 4d8kh2, 20d6kh3}kh2")
            with %Task{} = task <- expressions_from_braces(braces_string),
                 [%Rollable{} | _rest] = expressions <- Task.await(task),
                 {:ok, %Modifier{} = modifier} <- Modifier.scan(raw) do
              {:ok, expressions, modifier}
            else
              other -> {:error, inspect(other)}
            end

          _other ->
            {:error, "not handled yet"}
        end
    end
  end
end
