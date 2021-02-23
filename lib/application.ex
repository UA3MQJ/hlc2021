defmodule Worki.Application do
  use Application

  require Logger

  def start(_type, _args) do
    Logger.info ("Start server...")

    address = System.get_env("ADDRESS", "localhost")
    :persistent_term.put(:url, "http://#{address}:8000")

    Logger.info ("Start server... http://#{address}:8000 ")

    children = [
      {LicSever, []},
      {GameSever, []},
    ]

    opts = [strategy: :one_for_one, name: Worki.Supervisor]

    Supervisor.start_link(children, opts)
  end

end
