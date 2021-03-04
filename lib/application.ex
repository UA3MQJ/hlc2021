defmodule Worki.Application do
  use Application

  require Logger

  @lic_pool [
    name: :lic_pool,
    size: 10,
    max_overflow: 0
  ]

  @dig_pool [
    name: :dig_pool,
    size: 10,
    max_overflow: 0
  ]

  @test_pool [
    name: :test_pool,
    size: 2,
    max_overflow: 0
  ]

  defp lic_pool_config() do
    [
      {:name, {:local, @lic_pool[:name]}},
      {:worker_module, LicServer},
      {:size, @lic_pool[:size]},
      {:max_overflow, @lic_pool[:max_overflow]}
    ]
  end

  defp dig_pool_config() do
    [
      {:name, {:local, @dig_pool[:name]}},
      {:worker_module, DigServer},
      {:size, @dig_pool[:size]},
      {:max_overflow, @dig_pool[:max_overflow]}
    ]
  end

  defp test_pool_config() do
    [
      {:name, {:local, @test_pool[:name]}},
      {:worker_module, TestServer},
      {:size, @test_pool[:size]},
      {:max_overflow, @test_pool[:max_overflow]}
    ]
  end

  def start(_type, _args) do
    Logger.info ("Start server...")

    address = System.get_env("ADDRESS", "localhost")
    :persistent_term.put(:url, "http://#{address}:8000")

    Logger.info ("Start server... http://#{address}:8000 ")

    children = [
      {CashServer, []},
      {WRServer, []},
      :poolboy.child_spec(@lic_pool[:name], lic_pool_config(), []),
      :poolboy.child_spec(@test_pool[:name], test_pool_config(), []),
      :poolboy.child_spec(@dig_pool[:name], dig_pool_config(), []),
      {GameServer, []},
    ]

    opts = [strategy: :one_for_one, name: Worki.Supervisor]

    Supervisor.start_link(children, opts)
  end

end
