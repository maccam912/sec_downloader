defmodule SecDownloader.Counter do
  use GenServer

  def start_link(n) do
    GenServer.start_link(__MODULE__, n, name: __MODULE__)
  end

  def inc() do
    GenServer.cast(__MODULE__, :inc)
  end

  def unlock() do
    GenServer.call(__MODULE__, :unlock)
  end

  def init(n) do
    {:ok, {0, n}}
  end

  def handle_cast(:inc, {state, n}) do
    IO.puts("#{state}\t/\t#{n}")
    {:noreply, {state + 1, n}}
  end

  def handle_call(:unlock, state) do
    Process.sleep(100)
    {:noreply, :ok, state}
  end
end
