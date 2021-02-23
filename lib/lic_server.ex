defmodule LicSever do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_license() do
    GenServer.call(__MODULE__, :get_license, 60000)
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "LicServer init"
    {:ok, nil}
  end


  @impl true
  def handle_call(:get_license, _from, state) do
    lic = case state do
      nil -> get_lic()
      _else -> state
    end
    %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = lic
    # Logger.debug ">> lic=#{inspect lic}"
    case digAllowed==(digUsed+1) do
      true ->
        {:reply, id, get_lic()}
      false ->
        {:reply, id, %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}}
    end
  end

  defp get_lic() do
    case Worki.licenses([]) do
      {:ok, response} ->
        case Jason.decode(response.body) do
          {:ok, %{"digAllowed" => _, "digUsed" => _, "id" => _}=lic}  -> lic
          _else ->
            :timer.sleep(100)
            get_lic()
        end
      _error ->
        :timer.sleep(100)
        get_lic()
    end
  end

end
