defmodule CashSever do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: CashSever)
  end

  def put_cash(cash) do
    GenServer.cast(CashSever, {:put_cash, cash})
  end

  def get_cash() do
    GenServer.call(CashSever, :get_cash, 60000)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "CashSever init pid=#{inspect self()}"
    {:ok, []}
  end

  @impl true
  def handle_cast({:put_cash, cash}, state) do
    Logger.debug ">>> put cash=#{inspect cash}"
    {:noreply, cash ++ state}
  end
  @impl true
  def handle_call(:get_cash, _from, []) do
    {:reply, [], []}
  end
  @impl true
  def handle_call(:get_cash, _from, [hd|tl]) do
    # Logger.debug ">> hd = #{inspect hd}"
    {:reply, [hd], tl}
  end

end
