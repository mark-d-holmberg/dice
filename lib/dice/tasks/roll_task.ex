defmodule Dice.Tasks.RollTask do
  @moduledoc """
  A Task to roll dice
  """
  use Task

  def start_link(arg) do
    IO.puts("[RollTask.start_link]")
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(min, max) do
    Enum.random(min..max)
  end
end

# Task.Supervisor.async(DiceSupervisor, fn ->
#   # Do something
#   Dice.Tasks.RollTask.run(1, 20)
# end)
# |> Task.await()
