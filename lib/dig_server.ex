defmodule DigServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def do_dig(x, y, lvl, count) do
    case :poolboy.checkout(:dig_pool, false) do
      :full ->
        Process.sleep(100)
        do_dig(x, y, lvl, count)
      worker_pid ->
        GenServer.cast(worker_pid, {:do_dig, x, y, lvl, count})
    end
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "DigServer init pid=#{inspect self()}"
    {:ok, nil}
  end

  @impl true
  def handle_cast({:do_dig, x, y, lvl, count}, state) do
    Worki.do_dig(x, y, lvl, count)

    WRServer.release(:dig_pool, self())
    {:noreply, state}
  end

end