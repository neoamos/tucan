defmodule App.Task do
  use GenServer

  def start_link state do
    GenServer.start_link(__MODULE__, state )
  end

  def init(state) do
    schedule_work(state,100000000)
    {:ok, state}
  end

  def handle_info(:job, state) do
    {usec, :ok} = :timer.tc(fn ->
      apply(state.job, state.args)
      :ok
    end)
    IO.puts("Task took #{usec*0.000001} seconds")
    schedule_work(state, usec/1_000) # Reschedule once more
    {:noreply, state}
  end

  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  defp schedule_work(state, deduction \\ 0) do
    time = 60 * 60 * 1000 * state.interval
    time = if time > deduction do
      time-deduction
    else
      0
    end
    time = trunc(time)
    IO.puts("Scheduling #{state.name} in #{time} ms")
    Process.send_after(self(), :job,  time)
  end
end
