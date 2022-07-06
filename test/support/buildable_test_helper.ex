defmodule Dice.Support.BuildableTestHelper do
  @moduledoc """
  Context macro for our model tests for buildable.
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @model Keyword.get(opts, :model)

      # For struct!
      @required_keys Keyword.get(opts, :required_keys, name: "Some Name")

      setup do
        {:ok, %{required_keys: @required_keys}}
      end

      describe "concerning validations and factories" do
        test "build/1 returns a valid struct when given a map with string keys", %{
          required_keys: required_keys
        } do
          string_keys =
            required_keys
            |> Enum.into(%{})
            |> Dice.MapUtils.stringify_keys()

          assert {:ok, model = %@model{}} = @model.build(string_keys)
        end

        test "build/1 ignores stupid keys which don't exist when given a map", %{
          required_keys: required_keys
        } do
          string_keys =
            required_keys
            |> Enum.into(%{poop: true})
            |> Dice.MapUtils.stringify_keys()

          assert {:ok, model = %@model{}} = @model.build(string_keys)

          # Make sure it ignores stupid, non-existent keys
          assert_raise KeyError, fn ->
            model.poop
          end
        end

        test "build/1 returns a valid struct when given a keyword list", %{
          required_keys: required_keys
        } do
          assert {:ok, model = %@model{}} = @model.build(required_keys)
        end

        test "build/1 ignores stupid keys which don't exist when given a keyword list", %{
          required_keys: required_keys
        } do
          new_list = Keyword.put(required_keys, :poop, true)
          assert {:ok, model = %@model{}} = @model.build(new_list)

          # Make sure it ignores stupid, non-existent keys
          assert_raise KeyError, fn ->
            model.poop
          end
        end
      end
    end
  end
end
