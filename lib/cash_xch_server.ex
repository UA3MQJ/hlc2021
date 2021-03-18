defmodule CashXchServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def do_exchange(_treasure, 1) do
    :ok
  end

  def do_exchange(treasure, lvl) do
    case :poolboy.checkout(:xch_pool, false) do
      :full ->
        Process.sleep(10)
        do_exchange(treasure, lvl)
      worker_pid ->
        Worki.cnt_inc(:xch_count)
        GenServer.cast(worker_pid, {:do_exchange, treasure})
    end
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "CashXchServer init pid=#{inspect self()}"
    Worki.cnt_new(:exchanged)
    {:ok, nil}
  end

  @impl true
  def handle_cast({:do_exchange, treasure}, state) do
    Worki.cash(treasure)

    WRServer.release(:xch_pool, self())
    Worki.cnt_inc(:exchanged)
    Worki.cnt_dec(:xch_count)
    {:noreply, state}
  end

end
