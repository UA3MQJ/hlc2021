#!/bin/bash
docker build -t elixir .

docker tag elixir stor.highloadcup.ru/rally/real_frog

docker push stor.highloadcup.ru/rally/real_frog
