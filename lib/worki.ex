defmodule Worki do
  require Logger

  def do_dig(_, _, 11, _), do: :ok
  def do_dig(_, _, _, 0), do: :ok
  def do_dig(x, y, lvl, count) do
    res = dig(LicSever.get_license(), x, y, lvl)
    # Logger.debug ">>> do_dig  res=#{inspect res}\r\n x=#{inspect x} y=#{inspect y} lvl=#{inspect lvl} count=#{inspect count}"
    case res do
      {:ok, %{status_code: 404}} -> # копаем дальше
        do_dig(x, y, lvl+1, count)
      {:ok, %{status_code: 200} = response} -> # выкопали
        case Jason.decode(response.body) do
          {:ok, [treasure]}  ->
            treasure2cash(treasure)
            # Logger.debug ">>> do_dig  treasure=#{inspect treasure}"
            do_dig(x, y, lvl+1, count-1)
          _else ->
            :ok
        end
      _else -> :ok # какие-то ошибки
    end
  end

  def r_explore(x1, x2, y) do
    count = clean_explore(x1, y, (x2-x1)+1, 1) # v
    cond do
      count > 0 -> r_explore(x1, x2, y, count)
      true  -> []
    end
  end
  def r_explore(_, _, _, 0 = _count) do
    []
  end
  def r_explore(x, x, y, count) do  # x1==x2
    [{x, x, y, count}]
  end
  def r_explore(x1, x2, y, count) do
    # Logger.debug ">> r_explore(x1=#{x1}, x2=#{x2}, y=#{y}, count=#{count}) "

    # range 10, 11, 12, 13, 14, 15, 16, 17
    range = x2 - x1 + 1 # должно быть 8
    left = x1
    center = x1 + div(range-1, 2)
    right = x2
    l_x1 = left
    l_x2 = center
    r_x1 = center+1
    r_x2 = right

    # Logger.debug ">> left=#{left}, center=#{center}, right=#{right} "
    # Logger.debug ">> l_x1=#{l_x1}..l_x2=#{l_x2}, r_x1=#{r_x1}..r_x2=#{r_x2}"
    # нужно только одну половину
    count_l = clean_explore(l_x1, y, l_x2-l_x1+1, 1)
    count_r = count - count_l

    r_explore(l_x1, l_x2, y, count_l) ++ r_explore(r_x1, r_x2, y, count_r)
  end

  # заглушка проверочная
  # def clean_explore(posX, posY, sizeX, sizeY) do
  #   Logger.debug ">> clean_explore(#{posX}, #{posY}, #{sizeX}, #{sizeY})  -> amount = #{sizeX*sizeY}"
  #   sizeX*sizeY
  # end
  def clean_explore(posX, posY, sizeX, sizeY) do
    # Logger.debug ">> explore(#{posX}, #{posY}, #{sizeX}, #{sizeY}) "
    case explore(posX, posY, sizeX, sizeY) do
      %{status_code: 200} = response ->
        case Jason.decode(response.body) do
          {:ok, body}  ->
            %{"amount" => amount, "area" => _area} = body
            # Logger.debug ">>>>> explore(#{posX}, #{posY}, #{sizeX}, #{sizeY}) -> amount = #{amount}"
            amount
          _else ->
            :timer.sleep(100)
            clean_explore(posX, posY, sizeX, sizeY)
        end
      _some_other_error->
        :timer.sleep(100)
        clean_explore(posX, posY, sizeX, sizeY)
    end
  end

  def do_explore(posX, posY, sizeX, sizeY) do
    case explore(posX, posY, sizeX, sizeY) do
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, body}  ->
            %{"amount" => amount, "area" => _area} = body
            # if amount>2 do
              # Task.start(Worki, :do_dig, [posX, posY, 1, amount])
              do_dig(posX, posY, 1, amount)
            # end
          _else ->
            :timer.sleep(100)
            do_explore(posX, posY, sizeX, sizeY)
        end
      _some_other_error->
        :timer.sleep(100)
        do_explore(posX, posY, sizeX, sizeY)
    end
  end

  # def game() do
  #   1..120_000
  #   |> Enum.map(fn(x)->

  #   end)
  # end

  def game() do
    # 12547 1поток
    # 13767 хитрый ехplore
    # ^ -
    # 16432 последовательный explore 512                 (сервер 32347)
    # 16096 параллельный explore 512 весь ряд (7 кусков) (сервер 32332)
    # 54316 копаем с платными лицензиями                 (сервер 222042)
    # 55288 копаем с платными лицензиями посл expl по 512(сервер 190513)
    # 22793 - по одной с платными                        (сервер 112307)
    # 23756 - по одной платными но не запоминая монетки  (сервер)
    Enum.map(0..3499, fn(x) ->
      Enum.map(0..3499, fn(y) ->

        # x1=x*512
        # x2=x*512+511

        # list = Worki.r_explore(x1,x2,y)

        # # последовательно
        # list
        # |> Enum.map(fn({tx, _, ty, amount}) ->
        #   do_dig(tx, ty, 1, amount)
        # end)
        amount = clean_explore(x, y, 1, 1)
        if amount > 0 do
          do_dig(x, y, 1, amount)
        end

      end)
    end)

    Logger.info("Complete...")
    :ok
  end

  def treasure2cash(treasure) do
    # cash(treasure)
    # Logger.debug(".")
    Task.start(Worki, :cash, [treasure])
  end

  def dig(licenseID, posX, posY, depth),
    do: post("/dig", %{licenseID: licenseID, posX: posX, posY: posY, depth: depth})

  def health_check(),
    do: get("/health-check")

  def balance(),
    do: get("/balance")

  def explore(posX, posY, sizeX, sizeY),
   do: post("/explore", %{posX: posX, posY: posY, sizeX: sizeX, sizeY: sizeY})

  def licenses(coins),
    do: post("/licenses", coins)

  # def cash(treasure),
  #   do: post("/cash", treasure)
  def cash(treasure) do
    case post("/cash", treasure) do
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, body}  ->
            # Logger.debug "cash body=#{inspect body}"
            CashSever.put_cash(body)
            :ok
          _else ->
            :timer.sleep(100)
            cash(treasure)
        end
      _some_other_error->
        :timer.sleep(100)
        cash(treasure)
    end
  end

  # Jason.decode(response.body)

  # defp post(path, body) do
  #   headers = [{"Content-Type", "application/json"}]
  #   json_body = Jason.encode!(body)
  #   # json_body = :jiffy.encode(body)
  #   url = :persistent_term.get(:url)
  #   HTTPoison.post(url<>path, json_body, headers, [])
  # end

  defp post(path, body) do
    headers = ["Content-Type": "application/json"]
    # json_body = Jason.encode!(body)
    json_body = :jiffy.encode(body)
    url = :persistent_term.get(:url)
    HTTPotion.post(url<>path, [body: json_body, headers: headers])
  end

  defp get(path) do
    headers = [{"Content-Type", "application/json"}]
    url = :persistent_term.get(:url)
    HTTPoison.get(url<>path, headers)
  end

  def perf do
    # 00:54:20.673 [debug] perf time time = 5807 ms
    # time1 = :os.system_time(:millisecond)
    # 1..1000 |> Enum.map(fn(x) -> Worki.clean_explore(x, 0, 1, 1) end )
    # time2 = :os.system_time(:millisecond)

    # Logger.debug "perf time time = #{time2 - time1} ms"

    time1 = :os.system_time(:millisecond)
    1..1000
    |> Enum.map(fn(x) -> Task.async(Worki, :clean_explore, [x, 0, 1, 1]) end )
    |> Enum.map(fn(ref) -> Task.await(ref, 60000) end )
    time2 = :os.system_time(:millisecond)

    Logger.debug "perf time time = #{time2 - time1} ms"
  end
end
