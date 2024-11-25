defmodule LoggerBackendSqlTest do
  use ExUnit.Case
  doctest LoggerBackendSql

  test "greets the world" do
    assert LoggerBackendSql.hello() == :world
  end
end
