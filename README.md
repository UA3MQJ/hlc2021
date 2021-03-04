# Worki

## Рецепты

создать образ

 docker build -t elixir .

подключиться и зайти в него

 docker run -i -t <id контейнера> /bin/bash

запустить

 docker run --rm -t elixir

загрузка контейнера на решение

 docker tag elixir stor.highloadcup.ru/rally/shy_beaver
 docker push stor.highloadcup.ru/rally/shy_beaver

/explore не требует лицензий
/dig всегда требует лицензию
 dig может выдать ['treasureid']
 и его можно обменять на монеты [id1, id2, id3...]

/licenses 
 [] - бесплатная лицензия - 3 копания
 [idмонетки] - платная лицензия - 5 копаний
 активными может быть одновременно только 10 лицензий


1..120_000 |> Enum.map(fn(x)-> LicServer.get_license() end)

dig(LicServer.get_license(), x, y, lvl)
1..1000 |> Enum.map(fn(_)-> Worki.dig(LicServer.get_license(), 0, 0, 1) end); nil

time1 = :os.system_time(:millisecond)
1..100 |> Enum.map(fn(x) -> Worki.clean_explore(x, 0, 1, 1) end )

wrk -t500 -c1000 -d10s -s ./script.lua http://localhost:8000/explore

wrk -t500 -c1000 -d10s  http://localhost:4000/explore

1..4 |> Enum.map(fn(_)-> Task.async(TestServer, :get_license, []) end) |> Enum.map(fn(ref)-> Task.await(ref) end)

