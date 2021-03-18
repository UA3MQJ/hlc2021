defmodule CoordsServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put_coords(x, y, amount) do
    GenServer.cast(__MODULE__, {:put_coords, x, y, amount})
  end

  def get_coord() do
    GenServer.call(__MODULE__, :get_coords, 60000)
  end

  def get_coord_count() do
    Worki.cnt_read(:coord_count)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "CashServer init pid=#{inspect self()}"
    Worki.cnt_new(:coord_count)
    {:ok, []}
  end

  @impl true
  def handle_cast({:put_coords, x, y, amount}, state) do
    Worki.cnt_inc(:coord_count)
    {:noreply, [{x, y, amount}] ++ state}
  end

  @impl true
  def handle_call(:get_coords, _from, []) do
    {:reply, nil, []}
  end
  @impl true
  def handle_call(:get_coords, _from, [hd|tl]) do
    # Logger.debug ">> hd = #{inspect hd}"
    Worki.cnt_dec(:coord_count)
    {:reply, hd, tl}
  end

end
