defmodule SecDownloader.Counter do
  use GenServer

  def start_link(n) do
    GenServer.start_link(__MODULE__, n, name: __MODULE__)
  end

  def inc() do
    GenServer.cast(__MODULE__, :inc)
  end

  def init(n) do
    {:ok, {0, n}}
  end

  def handle_cast(:inc, {state, n}) do
    IO.puts("#{state}\t/\t#{n}")
    {:noreply, {state + 1, n}}
  end
end
