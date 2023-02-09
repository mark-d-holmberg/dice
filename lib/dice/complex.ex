defmodule Dice.Complex do
  @moduledoc """
  Complex parsing of expressions for the quantity or sides
  """
  use Dice.ContextClient

  # List of valid regex aliases
  @valid_regex_atoms [
    :count_success,
    :complex_quantity_multiplier,
    :complex,
    :starts_with,
    :ends_with,
    :complex_multiplier_ends_with,
    :braces_with_maybe_modifier,
    :roll_modifier_addition
  ]

  use Dice.Matching, filters: @valid_regex_atoms

  @doc """
  Process a complex builder to match and reduce the expressions if possible.
  """
  @spec process_complex({:ok, Builder.t()} | Builder.t()) ::
          {:ok, Builder.t()} | {:error, String.t()}
  def process_complex({:ok, %Builder{} = b}), do: process_complex(b)

  def process_complex(%Builder{type: :complex, raw: raw} = builder) do
    with {regex, kind}
         when kind in @valid_regex_atoms <-
           matching?(raw) do
      case kind do
        :complex_quantity_multiplier ->
          # "(1d20*2)d(1d10)"
          with %{
                 "first_die" => first_die,
                 "multiplier" => _multiplier,
                 "second_die" => second_die
               } <- Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{} = new_quantity_expr}} <-
                 Parser.parse(first_die),
               {:ok, %Rollable{expressable: %Expression{} = new_sides_expr}} <-
                 Parser.parse(second_die) do
            {:ok,
             %{
               builder
               | quantity_expression: new_quantity_expr,
                 sides_expression: new_sides_expr
             }}
          end

        :complex_multiplier_ends_with ->
          # "(1d20*2)d20"
          with %{
                 "first_die" => first_die,
                 "multiplier" => _multiplier,
                 "ends_with" => ends_with
               } <- Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{} = new_quantity_expr}} <-
                 Parser.parse(first_die),
               {:ok, %Rollable{expressable: %Expression{} = new_sides_expr}} <-
                 Parser.parse(ends_with) do
            {:ok,
             %{
               builder
               | quantity_expression: new_quantity_expr,
                 sides_expression: new_sides_expr
             }}
          end

        :complex ->
          # "(1d4)d(2d8)"
          with %{"first_die" => first_die, "second_die" => second_die} <-
                 Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{} = new_quantity_expr}} <-
                 Parser.parse(first_die),
               {:ok, %Rollable{expressable: %Expression{} = new_sides_expr}} <-
                 Parser.parse(second_die) do
            {:ok,
             %{
               builder
               | quantity_expression: new_quantity_expr,
                 sides_expression: new_sides_expr
             }}
          end

        :starts_with ->
          # "(1d4)d20"
          with %{"first_die" => first_die, "ends_with" => ends_with} <-
                 Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{} = new_quantity_expr}} <-
                 Parser.parse(first_die),
               {:ok, %Rollable{expressable: %Expression{sides: new_sides}}} <-
                 Parser.parse(ends_with) do
            {:ok,
             %{
               builder
               | quantity_expression: new_quantity_expr,
                 sides_expression: nil,
                 sides: new_sides
             }}
          end

        :ends_with ->
          # "6d(2d12)"
          with %{"quantity" => new_quantity, "second_die" => second_die} <-
                 Regex.named_captures(regex, raw),
               {:ok, %Rollable{expressable: %Expression{} = new_sides_expr}} <-
                 Parser.parse(second_die) do
            {:ok,
             %{
               builder
               | sides_expression: new_sides_expr,
                 quantity_expression: nil,
                 quantity: String.to_integer(new_quantity)
             }}
          end
      end
    else
      _ -> {:error, "No regex matches the raw string: #{inspect(raw)}"}
    end
  end
end
