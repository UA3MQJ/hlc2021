FROM elixir:1.11.3-alpine
LABEL authors="Alexey Bolshakov <ua3mqj@gmail.com>"
ADD . /app
WORKDIR /app
RUN apt-get update
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile
CMD ./start.sh