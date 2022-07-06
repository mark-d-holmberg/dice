# use Test.Support.DataCase
defmodule Test.Support.DataCase do
  @moduledoc """
  Common types of test cases
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      def evens() do
        1..20
        |> Enum.to_list()
        |> Enum.reject(&(rem(&1, 2) != 0))
      end

      def odds() do
        1..20
        |> Enum.to_list()
        |> Enum.reject(&(rem(&1, 2) == 0))
      end

      def samples(:simple) do
        for x <- evens(),
            y <- evens() do
          ["#{x}d#{y}", "(#{x}d#{y})"]
        end
        |> List.flatten()
      end

      # Slightly more involved expressions
      def samples(:complex) do
        [
          "(10d10)",
          "(10d2*3)d(4d8)kh",
          "(10d2*3)d(4d8)kh3",
          "(10d4)",
          "(1d20*2)d(1d10)",
          "(1d20*2)d20",
          "(1d4)",
          "(1d4)d(2d8)",
          "(1d4)d20",
          "(1d4*2)",
          "(2d18)",
          "(2d4)d8",
          "(2d6)",
          "(2d8)d10",
          "(4d10)",
          "10d4kh3",
          "12d20kl3",
          "12d4",
          "1d(1d20)",
          "1d20*2",
          "1d4",
          "1d4*2",
          "1d6",
          "2d20kh",
          "2d20kl",
          "3d12",
          "4d(1d10)",
          "4d6kh3",
          "5d(1d6)",
          "6d(2d12)",
          "d10",
          "d20",
          "d8",
          "{2d10kh2}",
          "{4d10}kl2",
          "{4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3, 4d6kh3}",
          "{6d6, 5d8, 4d10, 3d12}cs<10",
          "{6d6, 5d8, 4d10, 3d12}cs<=10",
          "{6d6, 5d8, 4d10, 3d12}cs=10",
          "{6d6, 5d8, 4d10, 3d12}cs>10",
          "{6d6, 5d8, 4d10, 3d12}cs>=10",
          "3d12ms>(4d6)",
          "{3d12, 2d10, 4d12}ms>(4d6)",
          "3d12ms>({4d6, 3d12}kh)",
          "3d12ms>{4d6, 3d12}kh"
        ]
      end
    end
  end
end
