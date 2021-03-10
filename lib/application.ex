defmodule Worki.Application do
  use Application

  require Logger

  # 1-4541 2-9907 3-14306 4-11528
  # 5-15607 6-13309 7-13653 8-15813
  # 9-13541 10-13780 11-15813 12-14931
  # 13-14430 50-15926

  @dig_pool [
    name: :dig_pool,
    size: 16,
    max_overflow: 0
  ]

  @test_pool [
    name: :test_pool,
    size: 2,
    max_overflow: 0
  ]

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
    # Logger.info ("Start server...")

    address = System.get_env("ADDRESS", "localhost")
    :persistent_term.put(:url, "http://#{address}:8000")
    :persistent_term.put(:rdy, false)

    Worki.cnt_new(:dig_count)

    Logger.info ("Start server... http://#{address}:8000 ")

    children = [
      {LicServer, []},
      {CashServer, []},
      {WRServer, []},
      :poolboy.child_spec(@test_pool[:name], test_pool_config(), []),
      :poolboy.child_spec(@dig_pool[:name], dig_pool_config(), []),
      {GameServer, []},
    ]

    opts = [strategy: :one_for_one, name: Worki.Supervisor]

    Supervisor.start_link(children, opts)
  end

end
