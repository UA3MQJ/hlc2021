defmodule WRServer do
  use GenServer
  require Logger

  def release(pool, pid) do
    send(WRServer, {:release, pool, pid})
  end

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "WRServer init"
    {:ok, nil}
  end

  @impl true
  def handle_info({:release, pool, pid}, state) do
    # Logger.debug ">>> Release #{pool} #{inspect pid}"
    :ok = :poolboy.checkin(pool, pid)
    {:noreply, state}
  end

end
