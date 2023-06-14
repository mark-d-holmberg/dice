defmodule Dice.DiceSupervisor do
  @moduledoc """
  A supervisor to monitor RollTask
  """

  # Automatically defines child_spec/1
  use Supervisor

  def start_link(init_arg) do
    IO.puts("[DiceSupervisor.start_link]")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # NOTE: this can "supervise" many different TYPES of tasks... Rolling, Calculating modifiers, etc...
  @impl true
  def init(_init_arg) do
    children = [
      {Dice.Tasks.RollTask, [:hello]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
