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
    end
  end

  def do_explore(posX, posY, sizeX, sizeY) do
    case explore(posX, posY, sizeX, sizeY) do
      {:error, _} -> :ok
      # {:ok, %{body: %{"amount" => 0}}} -> :ok
      # {:ok, %{body: %{"amount" => amount, "area" => area}}} ->
      #   if amount>0 do
      #     Logger.debug ">> area=#{inspect area} amount=#{inspect amount}"
      #     # res = do_dig(x, y, 1, amount)
      #     # Logger.debug ">>>> res=#{inspect res}"
      #     # do_dig(x, y, 1, amount)
      #     # Task.start(Worki, :do_dig, [posX, posY, 1, amount])
      #   end
      {:ok, %{status_code: 200} = response} ->
        case Jason.decode(response.body) do
          {:ok, body}  ->
            %{"amount" => amount, "area" => area} = body
            if amount>0 do
              # Task.start(Worki, :do_dig, [posX, posY, 1, amount])
              do_dig(posX, posY, 1, amount)
            end
          _else -> :ok
        end
      _some_other_error-> :ok
    end
  end

  def game() do

    Enum.map(0..3500, fn(x) ->
      Enum.map(0..3500, fn(y) ->
        do_explore(x, y, 1, 1)
        # Task.start(Worki, :do_explore, [x, y, 1, 1])
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

  def cash(treasure),
    do: post("/cash", treasure)

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
