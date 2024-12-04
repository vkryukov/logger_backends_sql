defmodule LoggerBackend.SQLTest do
  use LoggerBackends.SQL.RepoCase, async: false
  require Logger

  @async_wait 100

  test "log level is :info" do
    LoggerBackends.configure(LoggerBackends.SQL, level: :info)
    Logger.debug("debug log")
    Logger.info("info log")
    Logger.warning("warning log")
    Logger.error("error log")

    Process.sleep(@async_wait)

    logs =
      from(l in "logs", select: {l.level, l.message})
      |> TestRepo.all()
      |> Enum.sort()

    assert logs == [
             {"error", "error log"},
             {"info", "info log"},
             {"warn", "warning log"}
           ]
  end

  test "log level is :debug" do
    LoggerBackends.configure(LoggerBackends.SQL, level: :debug)
    Logger.debug("debug log")
    Logger.info("info log")
    Logger.warning("warning log")
    Logger.error("error log")

    Process.sleep(@async_wait)

    logs =
      from(l in "logs", select: {l.level, l.message})
      |> TestRepo.all()
      |> Enum.sort()

    assert logs == [
             {"debug", "debug log"},
             {"error", "error log"},
             {"info", "info log"},
             {"warn", "warning log"}
           ]
  end
end
