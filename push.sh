#!/bin/bash
docker build -t elixir .

docker tag elixir stor.highloadcup.ru/rally/quick_centipede

docker push stor.highloadcup.ru/rally/quick_centipede
