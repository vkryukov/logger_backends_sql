defmodule LoggerBackends.SQL.TestRepo do
  use Ecto.Repo,
    otp_app: :logger_backends_sql,
    adapter: Ecto.Adapters.SQLite3
end
