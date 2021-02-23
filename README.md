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

