defmodule GameSever do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "GameSever init"
    send(self(), :postinit)
    {:ok, []}
  end

  @impl true
  def handle_info(:postinit, state) do
    Logger.info("GameSever postinit")
    Logger.info("health_check")
    wait_health_check()
    Logger.info("health_check - ok")
    :timer.sleep(100)
    # Task.start(Worki, :game, [])

    {:noreply, state}
  end

  defp wait_health_check do
    case Worki.health_check do
      {:ok, _} -> :ok
      _else ->
        :timer.sleep(100)
        wait_health_check
    end
  end

end
