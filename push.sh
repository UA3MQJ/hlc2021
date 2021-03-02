#!/bin/bash
docker build -t elixir .

docker tag elixir stor.highloadcup.ru/rally/shy_beaver

docker push stor.highloadcup.ru/rally/shy_beaver
