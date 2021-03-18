defmodule DigServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def do_dig() do
    case :poolboy.checkout(:dig_pool, false) do
      :full ->
        Process.sleep(100)
        do_dig()
      worker_pid ->
        GenServer.cast(worker_pid, :do_dig)
    end
  end

  def do_dig(x, y, lvl, count) do
    case :poolboy.checkout(:dig_pool, false) do
      :full ->
        Process.sleep(100)
        do_dig(x, y, lvl, count)
      worker_pid ->
        Worki.cnt_inc(:dig_count)
        GenServer.cast(worker_pid, {:do_dig, x, y, lvl, count})
    end
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "DigServer init pid=#{inspect self()}"
    Worki.cnt_new(:digged)
    Worki.cnt_new(:explored)

    {:ok, nil}
  end

  @impl true
  def handle_cast({:do_dig, x, y, lvl, count}, state) do
    Worki.do_dig(x, y, lvl, count)

    WRServer.release(:dig_pool, self())
    Worki.cnt_dec(:dig_count)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:do_dig, state) do
    do_dig_always()

    {:noreply, state}
  end

  def do_dig_always() do
    case CoordsServer.get_coord() do
      {x, y, count} ->
        do_dig(x, y, 1, count)
      _else ->
        Process.sleep(10)
    end
    do_dig_always()
  end
end
