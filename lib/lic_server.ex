defmodule LicServer do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def get_license() do
    # GenServer.call(__MODULE__, :get_license, 60000)
    # :poolboy.transaction(:lic_pool, fn pid ->
    #   GenServer.call(pid, :get_license, 120000)
    # end)
    case :poolboy.checkout(:lic_pool, false) do
      :full ->
        Process.sleep(100)
        get_license()
      worker_pid ->
        GenServer.call(worker_pid, :get_license, 120000)
    end
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "LicServer init pid=#{inspect self()}"
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
    case digAllowed==(digUsed) do
      true ->
        # release after dig
        # WRServer.release(:lic_pool, self())
        new_lic = get_lic()
        %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = new_lic
        # Logger.debug ">>> lic pid=#{inspect self()} lic=#{inspect new_lic} new_lic id=#{inspect id}"
        {:reply, {id, self()}, %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}}
      false ->
        # WRServer.release(:lic_pool, self())
        # Logger.debug ">>> lic pid=#{inspect self()} lic=#{inspect lic} old_lic id=#{inspect id}"
        {:reply, {id, self()}, %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}}
    end
  end

  defp get_lic() do
    case Worki.licenses(CashServer.get_cash()) do
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, %{"digAllowed" => _, "digUsed" => _, "id" => _}=lic}  ->
            # Logger.debug ">>>>>> lic pid=#{inspect self()} lic=#{inspect lic}"
            lic
          _else ->
            # Logger.debug ">>>>>> lic error1"
            :timer.sleep(100)
            get_lic()
        end
      _error ->
        # Logger.debug ">>>>>> lic error2"
        :timer.sleep(100)
        get_lic()
    end
  end

end
