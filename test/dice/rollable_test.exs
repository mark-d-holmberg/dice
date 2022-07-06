defmodule Dice.RollableTest do
  use ExUnit.Case

  alias Dice.Rollable
  doctest Rollable

  describe "build/1" do
    test "it is a struct" do
      assert {:ok, %Rollable{}} = Rollable.build("1d4")
    end
  end
end
