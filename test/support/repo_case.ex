defmodule LoggerBackends.SQL.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias LoggerBackends.SQL.TestRepo

      import Ecto
      import Ecto.Query
      import LoggerBackends.SQL.RepoCase

      setup tags do
        pid =
          Ecto.Adapters.SQL.Sandbox.start_owner!(LoggerBackends.SQL.TestRepo,
            shared: not tags[:async]
          )

        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        :ok
      end
    end
  end
end
