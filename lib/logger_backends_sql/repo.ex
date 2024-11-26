defmodule LoggerBackends.SQL.Repo do
  use Ecto.Repo,
    otp_app: :logger_backends_sql,
    adapter: Ecto.Adapters.SQLite3

  def start(db_path) do
    start_link(database: db_path, pool_size: 1, timeout: 5000)
  end
end
