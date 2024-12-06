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

  test "able to log structs in metadata" do
    defmodule A do
      defstruct [:a]

      def new(a), do: %A{a: a}
    end

    [{_id, pid, :worker, [LoggerBackends.Watcher]}] =
      Supervisor.which_children(LoggerBackends.Supervisor)
      |> Enum.filter(fn {id, _, _, _} -> id == LoggerBackends.SQL end)

    ref = Process.monitor(pid)

    a = A.new(1)

    Logger.info("info log", a: a, a_map: %{a: a}, a_list: [a])

    refute_receive {:DOWN, ^ref, :process, ^pid, _reason}, 500
  end
end
