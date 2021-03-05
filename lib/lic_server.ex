defmodule LicServer do
  use GenServer
  require Logger

  @active_lic_count 10

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_license() do
    # fun = [{{:"$1", :"$2", :"$3", :"$4"}, [not: {:==, :"$2", :"$3"}], [:"$1"]}]
    # case :ets.select(:lics, fun) do
    #   [] ->
    #     :no_lics
    #   _else ->
        GenServer.call(__MODULE__, :get_license, 60_000)
    # end
  end

  def return_license(id) do
    GenServer.cast(__MODULE__, {:return_license, id})
  end

  # Server (callbacks)
  @impl true
  def init(_state) do
    Logger.info "LicServer init pid=#{inspect self()}"
    :ets.new(:lics, [:set, :public, :named_table])
    send(self(), :postinit)
    {:ok, nil}
  end

  @impl true
  def handle_info(:postinit, state) do
    Logger.info("LicServer postinit")
    Logger.info("LicServer wait health_check")
    wait_health_check()
    Logger.info("LicServer health_check - ok")
    # Task.start(Worki, :game, [])
    # %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}
    # id, digAllowed, gave, returned
    # {1, 3, 0, 0}
    # :ets.insert(:lics, {1, 3, 0, 0})

    # fun = :ets.fun2ms(fn({id, digAllowed, gave, returned}) when not(digAllowed==gave) -> id end)
    # [{{:"$1", :"$2", :"$3", :"$4"}, [not: {:==, :"$2", :"$3"}], [:"$1"]}]
    # select *
    # fun = :ets.fun2ms(fn({id, digAllowed, gave, returned}) -> {id, digAllowed, gave, returned} end)
    # :ets.select(:lics, fun)

    # %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = lic
    1..@active_lic_count
    |> Enum.map(fn(_)->
      %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = get_lic()
      # id, digAllowed, gave, returned
      :ets.insert(:lics, {id, digAllowed, digUsed, 0})
    end)

    {:noreply, state}
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
  def handle_call(:get_license, _from, state) do
    fun = [{{:"$1", :"$2", :"$3", :"$4"}, [not: {:==, :"$2", :"$3"}], [{{:"$1", :"$2", :"$3", :"$4"}}]}]

    res = :ets.select(:lics, fun)
    # Logger.debug ">> res=#{inspect res}"
    case res do
      [] ->
        {:reply, :no_lics, state}
      lics ->
        [lic|_] = lics
        {id, _digAllowed, _gave, _returned} = lic
        # :ets.insert(:lics, {id, digAllowed, gave+1, returned})
        :ets.update_counter(:lics, id, {3, 1})
        {:reply, id, state}
    end
    # lic = case state do
    #   nil -> get_lic()
    #   _else -> state
    # end
    # %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = lic
    # # Logger.debug ">> lic=#{inspect lic}"
    # case digAllowed==(digUsed) do
    #   true ->
    #     # release after dig
    #     # WRServer.release(:lic_pool, self())
    #     new_lic = get_lic()
    #     %{"digAllowed" => digAllowed, "digUsed" => digUsed, "id" => id} = new_lic
    #     # Logger.debug ">>> lic pid=#{inspect self()} lic=#{inspect new_lic} new_lic id=#{inspect id}"
    #     {:reply, {id, self()}, %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}}
    #   false ->
    #     # WRServer.release(:lic_pool, self())
    #     # Logger.debug ">>> lic pid=#{inspect self()} lic=#{inspect lic} old_lic id=#{inspect id}"
    #     {:reply, {id, self()}, %{"digAllowed" => digAllowed, "digUsed" => digUsed+1, "id" => id}}
    # end
  end

  @impl true
  def handle_cast({:return_license, id}, state) do
    :ets.update_counter(:lics, id, {4, 1})
    [{id, digAllowed, gave, returned}] = :ets.lookup(:lics, id)
    if (digAllowed==gave)and(gave==(returned)) do
      new_lic = get_lic()
      %{"digAllowed" => n_digAllowed, "digUsed" => n_digUsed, "id" => n_id} = new_lic
      # Logger.debug ">>> lic id=#{id} free - new new_lic=#{inspect new_lic}"
      :ets.insert(:lics, {n_id, n_digAllowed, n_digUsed, 0})
    end

    # case :ets.lookup(:lics, id) do
    #   [{id, digAllowed, gave, returned}] ->
    #     # :ets.insert(:lics, {id, digAllowed, gave, returned+1})
    #     :ets.update_counter(:lics, id, {4, 1})
    #     if (digAllowed==gave)and(gave==(returned+1)) do
    #       :ets.delete(:lics, id)
    #       %{"digAllowed" => n_digAllowed, "digUsed" => n_digUsed, "id" => n_id} = get_lic()
    #       # id, digAllowed, gave, returned
    #       :ets.insert(:lics, {n_id, n_digAllowed, n_digUsed, 0})
    #     end
    #   _else -> :ok
    # end
    {:noreply, state}
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
      error ->
        # Logger.debug ">>>>>> lic error2 error=#{inspect error}"
        :timer.sleep(100)
        get_lic()
    end
  end

end
