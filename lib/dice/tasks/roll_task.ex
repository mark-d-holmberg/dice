defmodule Dice.Tasks.RollTask do
  @moduledoc """
  A Task to roll dice
  """
  use Task

  def start_link(arg) do
    IO.puts("[RollTask.start_link], arg was: #{inspect(arg)}")
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(max) when is_integer(max) do
    Enum.random(1..max)
    |> IO.inspect()
  end

  def run(min, max) do
    Enum.random(min..max)
  end
end

# {:ok, pid} = Dice.DiceSupervisor.start_link(12)
# Supervisor.stop(pid, :normal)
# Supervisor.count_children(DiceSupervisor)

# Task.Supervisor.async(DiceSupervisor, fn ->
#   # Do something
#   Dice.Tasks.RollTask.run(1, 20)
# end)
# |> Task.await()
