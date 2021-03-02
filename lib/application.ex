defmodule Worki.Application do
  use Application

  require Logger

  @lic_pool [
    name: :lic_pool,
    size: 10,
    max_overflow: 0
  ]

  defp lic_pool_config() do
    [
      {:name, {:local, @lic_pool[:name]}},
      {:worker_module, LicSever},
      {:size, @lic_pool[:size]},
      {:max_overflow, @lic_pool[:max_overflow]}
    ]
  end

  def start(_type, _args) do
    Logger.info ("Start server...")

    address = System.get_env("ADDRESS", "localhost")
    :persistent_term.put(:url, "http://#{address}:8000")

    Logger.info ("Start server... http://#{address}:8000 ")

    children = [
      {CashSever, []},
      :poolboy.child_spec(@lic_pool[:name], lic_pool_config(), []),
      {GameSever, []},
    ]

    opts = [strategy: :one_for_one, name: Worki.Supervisor]

    Supervisor.start_link(children, opts)
  end

end
