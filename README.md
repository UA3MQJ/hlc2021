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


1..120_000 |> Enum.map(fn(x)-> LicSever.get_license() end)

dig(LicSever.get_license(), x, y, lvl)
1..1000 |> Enum.map(fn(_)-> Worki.dig(LicSever.get_license(), 0, 0, 1) end); nil
