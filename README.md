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

li = [0,0,2,0,0,1,0,3]
0..7

1 запрос. всего 
8 -> {0, 7, nil}
{x1, x2, count} = {0, 7, 6}

{0, 7, nil} 
{0, 7, 6} +
{0, 3, ?}, {4, 7, ?} +
{0, 3, 2}, {4, 7, 6 - 2 = 4}
{0, 3, 2}, {4, 7, 4}
