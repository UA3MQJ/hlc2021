defmodule GameServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "GameServer init"
    send(self(), :postinit)
    {:ok, []}
  end

  @impl true
  def handle_info(:postinit, state) do
    # Logger.info("GameServer postinit")
    # Logger.info("GameServer health_check")
    wait_health_check()
    # Logger.info("GameServer health_check - ok")
    :persistent_term.put(:rdy, true)
    :timer.sleep(100)
    Task.start(Worki, :game, [])
    Task.start(GameServer, :speedometer, [0, 8])
    # Task.start(GameServer, :dig_changer, [1])


    {:noreply, state}
  end

  defp wait_health_check do
    case Worki.health_check do
      {:ok, _} -> :ok
      _else ->
        :timer.sleep(100)
        wait_health_check()
    end
  end

  def speedometer(prev, prev2) do
    # :persistent_term.put(:dig_max, prev2)
    digged = Worki.cnt_read(:digged)
    speed = digged - prev
    Logger.debug ">>> speed=#{speed/10000} dig_count=#{prev2-1}"
    Process.sleep(10000)

    speedometer(digged, prev2)
  end

  # def dig_changer(count) do
  #   :persistent_term.put(:dig_max, count)
  #   Logger.debug ">>> dig_changer=#{count}"
  #   Process.sleep(20000)

  #   dig_changer(count+1)
  # end
end
