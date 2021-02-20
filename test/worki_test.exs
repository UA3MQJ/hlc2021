defmodule WorkiTest do
  use ExUnit.Case
  doctest Worki

  test "greets the world" do
    assert Worki.hello() == :world
  end
end
