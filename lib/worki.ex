defmodule Worki do
  require Logger

  def do_dig(_, _, 11, _), do: :ok
  def do_dig(_, _, _, 0), do: :ok
  def do_dig(x, y, lvl, count) do

    case LicServer.get_license() do
      :no_lics ->
        Process.sleep(100)
        do_dig(x, y, lvl, count)
      {lic_id, _} = lic ->
        # Logger.debug ">>> #{lic_id}"
        res = dig(lic_id, x, y, lvl)
        # Logger.debug ">>> do_dig  res=#{inspect res}\r\n x=#{inspect x} y=#{inspect y} lvl=#{inspect lvl} count=#{inspect count}"
        case res do
          {:ok, %{status_code: 404}} -> # копаем дальше
            LicServer.return_license(lic)
            # Logger.debug "<<< #{lic_id}"
            do_dig(x, y, lvl+1, count)
          {:ok, %{status_code: 200} = response} -> # выкопали
            LicServer.return_license(lic)
            # Logger.debug "<<< #{lic_id}"
            case Jason.decode(response.body) do
              {:ok, [treasure]}  ->
                Worki.cnt_inc(:digged)
                # treasure2cash(treasure)
                CashXchServer.do_exchange(treasure, lvl)
                # Logger.debug ">>> do_dig  treasure=#{inspect treasure}"
                do_dig(x, y, lvl+1, count-1)
              _else ->
                # Logger.debug ">>> do_dig error1"
                :ok
            end
          _else ->
            # Logger.debug ">>> do_dig error2"
            :ok # какие-то ошибки
        end
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
    Enum.map(1..count, fn(_)->
      Worki.cnt_inc(:explored)
    end)
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
            # :timer.sleep(100)
            clean_explore(posX, posY, sizeX, sizeY)
        end
      _some_other_error->
        # :timer.sleep(100)
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
              Task.start(Worki, :do_dig, [posX, posY, 1, amount])
              # do_dig(posX, posY, 1, amount)
            # end
          _else ->
            # :timer.sleep(100)
            do_explore(posX, posY, sizeX, sizeY)
        end
      _some_other_error->
        # :timer.sleep(100)
        do_explore(posX, posY, sizeX, sizeY)
    end
  end

  def game() do
    # 12547 1поток
    # 13767 хитрый ехplore
    # ^ -
    # 16432 последовательный explore 512                 (сервер 32347)
    # 16096 параллельный explore 512 весь ряд (7 кусков) (сервер 32332)
    # 54316 копаем с платными лицензиями                 (сервер 222042)
    # 55288 копаем с платными лицензиями посл expl по 512(сервер 190513)
    # 22793 - по одной с платными                        (сервер 112307)
    # 23756 - по одной платными но не запоминая монетки  (сервер 114099)
    # 16082 - 10dig воркеров с блокировкой 1x1/expore    (сервер 217244)
    # 51652 - 4dig умный explore - 3499                  (сервер 378099)
    # 20611! - починил lic. синхр lic. 10dig, expl3499   (сервер 573087)
    # 22265 - по одной платными                          (сервер 214368)
    # 172485 - кусками по 16                             (сервер 723115)
    # 167485 - кусками по 32 параллельно  4 таска        (сервер 172207)
    # ? -    - попытка вернуть по 16                     (сервер 760303)
    # ? -  еще попытка 0..218,0..3499                    (сервер 739642)
    # 157724 - новый сервер лицензий кусками по 16, 10dig(сервер 301999)
    # 178979 - --//-- 50dig                              (сервер 297386)
    # 19107-12s lic_queues кусками по 16                 (сервер 1)
    # 18206 lic_que fix                                  (сервер 207868)
    # 20585 lic_que + async_new lic                      (сервер 466632)
    # ?      --//-- + speedometer                        (сервер 476673)
    # 20642-12s 30 dig_workers                           (сервер 470312)
    # 20853-12s 10 dig_workers                           (сервер 463204)
    # ? 16 dig_workers                                   (сервер 472751)
    # 21225-12s 16 cash-xch workers                      (ceрвер 469308)
    # ? 8 cash-xch workers                               (ceрвер 494294)
    # ? 4 cash-xch workers                               (ceрвер 447250)
    # ? 2 cash-xch workers                               (ceрвер 485599)
    # ? 1 cash-xch workers                               (ceрвер 437747)
    # ? 8 cash-xch workers 16 dig                        (ceрвер 484284)
    # ? 8 cash-xch workers 8 dig                         (ceрвер 460858)
    # ? 8 cash-xch workers 30 dig                        (ceрвер 465385)
    # ? 4 cash-xch workers 30 dig                        (ceрвер 488102)
    # ? 2 cash-xch workers 30 dig                        (ceрвер 481535)
    # ? 4 cash-xch workers 30 dig                        (ceрвер 440467)
    # ? 8 cash-xch workers 16 dig                        (ceрвер 457317)
    # ? 4 cash-xch workers 30 dig                        (ceрвер 420879)
    # ? 8 cash-xch workers 16 dig                        (ceрвер 486046)
    # async r_explore 1                                  (ceрвер 484753)
    # async r_explore 2                                  (ceрвер 527432)
    # async r_explore 4                                  (ceрвер 578440)
    # async r_explore 8                                  (ceрвер 53471)
    # async r_explore 16                                 (ceрвер 53526)
    # async r_explore 5                                  (ceрвер 588359)
    # async r_explore 6                                  (ceрвер 596287)
    # async r_explore 7                                  (ceрвер 595382)
    # async r_explore 4                                  (ceрвер 577708)
    # async r_explore 8                                  (ceрвер 607261)
    # не обмениваю призы с 1го уровня                    (сервер 625226)
    # эксперимент с количеством explore - explored=60353
    # отвязанные друг от друга explore-dig               (сервер 624334)
    # не продавать 2 уровень                             (       623021)
    # не продавать 3 уровень                             (       609771)
    # не продавать 3 уровень                             (       623390)
    # все продавать                                      (       608740)

    Enum.map(0..218, fn(x) ->
      # Enum.map(0..3499, fn(y) ->
      Enum.map(0..435, fn(y) ->

        x1=x*16
        x2=x*16+15

        # list = Worki.r_explore(x1,x2,y)

        # list1 = Worki.r_explore(x1,x2,y*2)
        # list2 = Worki.r_explore(x1,x2,y*2 + 1)
        ref1 = Task.async(Worki, :r_explore, [x1,x2,y*8])
        ref2 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 1])
        ref3 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 2])
        ref4 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 3])
        ref5 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 4])
        ref6 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 5])
        ref7 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 6])
        ref8 = Task.async(Worki, :r_explore, [x1,x2,y*8 + 7])


        list1 = Task.await(ref1, 120_000)
        list2 = Task.await(ref2, 120_000)
        list3 = Task.await(ref3, 120_000)
        list4 = Task.await(ref4, 120_000)
        list5 = Task.await(ref5, 120_000)
        list6 = Task.await(ref6, 120_000)
        list7 = Task.await(ref7, 120_000)
        list8 = Task.await(ref8, 120_000)

        list = list1 ++ list2 ++ list3 ++ list4  ++ list5 ++ list6 ++ list7 ++ list8
            #  ++ list9 ++ list10 ++ list11 ++ list12 ++ list13 ++ list14 ++ list15 ++ list16


        list
        |> Enum.map(fn({tx, _, ty, amount}) ->
          CoordsServer.put_coords(tx, ty, amount)
        end)

        sleep_to_big()

        # # последовательно
        # list
        # |> Enum.map(fn({tx, _, ty, amount}) ->
        #   # do_dig(tx, ty, 1, amount)
        #   # Task.start(Worki, :do_dig, [tx, ty, 1, amount])
        #   DigServer.do_dig(tx, ty, 1, amount)
        # end)

        # # вообще по очереди
        # amount = clean_explore(x, y, 1, 1)
        # if amount > 0 do
        #   # do_dig(x, y, 1, amount)
        #   DigServer.do_dig(x, y, 1, amount)
        # end

      end)
    end)

    Logger.info("Complete...")
    :ok
  end

  def sleep_to_big() do
    count = CoordsServer.get_coord_count()
    case count > 100 do
      true ->
        # Logger.debug ">>> explorer - im sleep"
        Process.sleep(10)
        sleep_to_big()
      false ->
        :ok
    end
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
            CashServer.put_cash(body)
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
    # json_body = :jiffy.encode(body)
    url = :persistent_term.get(:url)
    HTTPoison.post(url<>path, json_body, headers, [])
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

    # time1 = :os.system_time(:millisecond)
    # 1..1000
    # |> Enum.map(fn(x) -> Task.async(Worki, :clean_explore, [x, 0, 1, 1]) end )
    # |> Enum.map(fn(ref) -> Task.await(ref, 60000) end )
    # time2 = :os.system_time(:millisecond)

    # Logger.debug "perf time time = #{time2 - time1} ms"

    # time1 = :os.system_time(:millisecond)
    # res = 1..100000
    # |> Enum.map(fn(x) -> Task.async(Worki, :get_t, ["http://localhost:4000/explore"]) end )
    # |> Enum.map(fn(ref) -> Task.await(ref, 60000) end )

    # # Logger.debug "res = #{inspect res}"
    # time2 = :os.system_time(:millisecond)

    # Logger.debug "perf time time = #{time2 - time1} ms"
  end

  # cnt_pt_incr(Counter) ->
  #   counters:add(persistent_term:get({?MODULE,Counter}),1,1).

  # cnt_pt_read(Counter) ->
  #   counters:get(persistent_term:get({?MODULE,Counter}),1).

  def cnt_new(counter) do
    ref = :counters.new(1,[:atomics])
    :persistent_term.put(counter, ref)
    ref
  end

  def cnt_read(counter) do
    :counters.get(:persistent_term.get(counter), 1)
  end

  def cnt_inc(counter) do
    :counters.add(:persistent_term.get(counter), 1, 1)
  end

  def cnt_dec(counter) do
    :counters.sub(:persistent_term.get(counter), 1, 1)
  end
end
