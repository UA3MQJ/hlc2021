defmodule CashServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put_cash(cash) do
    GenServer.cast(__MODULE__, {:put_cash, length(cash)})
  end

  def get_cash() do
    GenServer.call(__MODULE__, :get_cash, 60000)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "CashServer init pid=#{inspect self()}"
    {:ok, {0, 0}}
  end

  @impl true
  def handle_cast({:put_cash, count}, {sent, total}) do
    # Logger.debug ">>> put cash=#{inspect count}"
    {:noreply, {sent, total + count}}
  end
  @impl true
  def handle_call(:get_cash, _from, {sent, 0}) do
    {:reply, [], {sent, 0}}
  end
  @impl true
  def handle_call(:get_cash, _from, {sent, total}) do
    # Logger.debug ">> hd = #{inspect hd}"
    {:reply, [sent+1], {sent+1, total}}
  end

end
