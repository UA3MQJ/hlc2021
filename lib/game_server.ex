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
    # Task.start(GameServer, :speedometer, [0])


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

  def speedometer(prev) do
    digged = Worki.cnt_read(:digged)
    speed = digged - prev

    Logger.debug ">>> speed=#{speed/10000}"
    Process.sleep(10000)

    speedometer(digged)
  end

end
