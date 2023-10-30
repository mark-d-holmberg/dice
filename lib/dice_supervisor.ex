defmodule Dice.DiceSupervisor do
  @moduledoc """
  A supervisor to monitor RollTask
  """

  # Automatically defines child_spec/1
  use Supervisor

  def start_link(opts) do
    IO.puts("[DiceSupervisor.start_link], opts was: #{inspect(opts)}")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # NOTE: this can "supervise" many different TYPES of tasks... Rolling, Calculating modifiers, etc...
  @impl true
  def init(opts) do
    children = [
      {Dice.Tasks.RollTask, Keyword.get(opts, :max, 18)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
