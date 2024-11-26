defmodule LoggerBackend.SQLTest do
  use ExUnit.Case
  doctest LoggerBackends.SQL

  test "greets the world" do
    assert LoggerBackends.SQL.hello() == :world
  end
end
