defmodule TestServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def get_license() do
    case :poolboy.checkout(:test_pool, false) do
      :full ->
        Process.sleep(100)
        get_license()
      worker_pid ->
        GenServer.cast(worker_pid, :get_license)
    end
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.debug "TestServer init pid=#{inspect self()}"
    {:ok, nil}
  end


  @impl true
  def handle_cast(:get_license, state) do
    Logger.debug "TestServer handle_cast pid=#{inspect self()}"
    :timer.sleep(10000)

    WRServer.release(:test_pool, self())
    {:noreply, state}
  end

end
