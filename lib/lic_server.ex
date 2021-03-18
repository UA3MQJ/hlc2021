defmodule LicServer do
  use GenServer
  require Logger

  @active_lic_count 10

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_license() do
    GenServer.call(__MODULE__, :get_license, 60_000)
  end

  def return_license(lic) do
    GenServer.cast(__MODULE__, {:return_license, lic})
  end

  def add_license(lic) do
    GenServer.cast(__MODULE__, {:add_lic, lic})
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    # Logger.info "LicServer init pid=#{inspect self()}"
    send(self(), :postinit)
    {:ok, nil}
  end

  @impl true
  def handle_info(:postinit, _state) do

    wait_health_check()
    Logger.info("LicServer health_check - ok")

    1..@active_lic_count
      |> Enum.map(fn(_)->
        Task.start(LicServer, :get_lic_task, [])
      end)

    {:noreply, {:queue.new(), %{}}}
  end

  defp wait_health_check() do
    case :persistent_term.get(:rdy) do
      true -> :ok
      false ->
        Process.sleep(10)
        wait_health_check()
    end
  end

  @impl true
  def handle_call(:get_license, _from, {q_lic, map_out} = state) do
    case :queue.out(q_lic) do
      {:empty, _} ->
        {:reply, :no_lics, state}
      {{:value, lic}, new_q_lic} ->
        {:reply, lic, {new_q_lic, map_out}}
    end
  end

  @impl true
  def handle_cast({:return_license, {id, count}}, {q_lic, map_out} = _state) do
    lic_used_count = Map.get(map_out, id, 0)
    new_map_out = Map.put(map_out, id, lic_used_count+1)

    case count==(lic_used_count+1) do
      true ->
        Task.start(LicServer, :get_lic_task, [])
        new2_map_out = Map.drop(new_map_out, [id])
        {:noreply, {q_lic, new2_map_out}}
      false ->
        {:noreply, {q_lic, new_map_out}}
    end
  end

  @impl true
  def handle_cast({:add_lic, {id, digAllowed}}, {q_lic, map_out}) do
    # Logger.debug ">>> add_lic #{inspect {id, digAllowed}}"
    new_q_lic = 1..digAllowed
    |> Enum.reduce(q_lic, fn(_, acc)->
      :queue.in({id, digAllowed}, acc)
    end)

    {:noreply, {new_q_lic, map_out}}
  end
  def get_lic_task() do
    %{"digAllowed" => digAllowed, "digUsed" => _digUsed, "id" => id} = get_lic()
    add_license({id, digAllowed})
  end

  defp get_lic() do
    case Worki.licenses(CashServer.get_cash()) do
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, %{"digAllowed" => _, "digUsed" => _, "id" => _}=lic}  ->
            # Logger.debug ">>>>>> lic pid=#{inspect self()} lic=#{inspect lic}"
            lic
          error ->
            # Logger.debug ">>>>>> lic error1 error=#{inspect error}"
            :timer.sleep(100)
            get_lic()
        end
      {:ok, %{status_code: 409} = _response} ->
        {:error, "no more active licenses allowed"}
      error ->
        # Logger.debug ">>>>>> lic error2 error=#{inspect error}"
        :timer.sleep(100)
        get_lic()
    end
  end

end
