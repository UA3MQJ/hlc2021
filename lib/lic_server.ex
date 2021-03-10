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

  def return_license(id) do
    GenServer.cast(__MODULE__, {:return_license, id})
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

    q_lic = 1..@active_lic_count
      |> Enum.reduce(:queue.new(), fn(_, acc)->
        %{"digAllowed" => digAllowed, "digUsed" => _digUsed, "id" => id} = get_lic()
        # id, digAllowed, gave, returned
        new_acc = 1..digAllowed
        |> Enum.reduce(acc, fn(_, acc)->
          :queue.in({id, digAllowed}, acc)
        end)

        new_acc
      end)

    # Logger.debug ">>> q_lic=#{inspect q_lic}"
    map_out = %{}

    {:noreply, {q_lic, map_out}}
  end

  defp wait_health_check() do
    case :persistent_term.get(:rdy) do
      true -> :ok
      false ->
        Process.sleep(100)
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
        %{"digAllowed" => digAllowed, "digUsed" => _digUsed, "id" => id} = get_lic()
        # id, digAllowed, gave, returned
        new_q_lic = 1..digAllowed
        |> Enum.reduce(q_lic, fn(_, acc)->
          :queue.in({id, digAllowed}, acc)
        end)

        # Logger.debug ">>>> get new license new_state=#{inspect {new_q_lic, new_map_out}}"
        {:noreply, {new_q_lic, new_map_out}}
      false ->
        # Logger.debug ">>>> new_state=#{inspect {q_lic, new_map_out}}"
        {:noreply, {q_lic, new_map_out}}
    end
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
