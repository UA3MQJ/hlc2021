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
      {:ok, %{status_code: 200} = response} ->
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

  def game() do
    # 12547 1поток
    # 13767 хитрый ехplore
    # ^ -
    # 16432
    Enum.map(0..6, fn(x) ->
      Enum.map(0..3500, fn(y) ->
      # Enum.map(0..3500, fn(y) ->

        x1=x*512
        x2=x*512 + 512

        list = Worki.r_explore(x1,x2,y)

        # последовательно
        list
        |> Enum.map(fn({tx, _, ty, amount}) ->
          do_dig(tx, ty, 1, amount)
        end)

        # копаем параллельно
        # list
        # |> Enum.map(fn({tx, _, ty, amount}) ->
        #   Task.async(Worki, :do_dig, [tx, ty, 1, amount])
        # end)
        # |> Enum.map(fn(ref) ->
        #   Task.await(ref, 60000)
        # end)

        # do_explore(x, y, 1, 1)
        # Task.start(Worki, :do_explore, [x, y, 1, 1])
        # y1 = y*8
        # y2 = y*8 + 1
        # y3 = y*8 + 2
        # y4 = y*8 + 3
        # ref1 = Task.async(Worki, :do_explore, [x, y1, 1, 1])
        # ref2 = Task.async(Worki, :do_explore, [x, y2, 1, 1])
        # ref3 = Task.async(Worki, :do_explore, [x, y3, 1, 1])
        # ref4 = Task.async(Worki, :do_explore, [x, y4, 1, 1])
        # Task.await(ref1, 60000)
        # Task.await(ref2, 60000)
        # Task.await(ref3, 60000)
        # Task.await(ref4, 60000)
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
    case res = post("/cash", treasure) do
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, body}  ->
            # Logger.debug "cash body=#{inspect body}"
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

  defp post(path, body) do
    headers = [{"Content-Type", "application/json"}]
    json_body = Jason.encode!(body)
    url = :persistent_term.get(:url)
    HTTPoison.post(url<>path, json_body, headers)
  end

  defp get(path) do
    headers = [{"Content-Type", "application/json"}]
    url = :persistent_term.get(:url)
    HTTPoison.get(url<>path, headers)
  end

end
