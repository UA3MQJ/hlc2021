FROM elixir:1.11.3-alpine
LABEL authors="Alexey Bolshakov <ua3mqj@gmail.com>"
ARG APP_NAME=worki
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV} REPLACE_OS_VARS=true TERM=xterm
# ADD . /app
ADD config /app/config
ADD lib /app/lib
ADD test /app/test
ADD mix.exs /app
ADD mix.lock /app
ADD start.sh /app

WORKDIR /app

RUN apk update \
  && apk --no-cache --update add \
    bash \
    git \
  && mix local.rebar --force \
  && mix local.hex --force

RUN HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix do deps.get, deps.compile, compile

RUN MIX_ENV=${MIX_ENV} mix release
CMD ./start.sh
# ENTRYPOINT ["_build/prod/rel/worki/bin/worki", "start"]
