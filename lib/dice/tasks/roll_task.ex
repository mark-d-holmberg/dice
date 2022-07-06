defmodule Dice.Tasks.RollTask do
  @moduledoc """
  A Task to roll dice
  """
  use Task

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(min, max) do
    Enum.random(min..max)
  end
end

# Task.Supervisor.async(DiceSupervisor, fn ->
#   # Do something
#   Dice.Tasks.RollTask.run(nil)
# end)
# |> Task.await()
