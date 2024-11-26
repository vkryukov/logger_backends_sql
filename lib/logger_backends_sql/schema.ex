defmodule LoggerBackends.SQL.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @table_name Application.compile_env(:logger, LoggerBackends.SQL, [])
              |> Keyword.get(:table_name, "logs")

  @primary_key false
  schema @table_name do
    field(:time, :utc_datetime_usec)
    field(:message, :string)
    field(:meta, :map)
  end

  def changeset(log_entry \\ %__MODULE__{}, attrs) do
    log_entry
    |> cast(attrs, [:time, :message, :meta])
    |> validate_required([:time, :message])
  end

  @doc """
  Creates the logging table if it doesn't exist.
  Safe to call multiple times - will only create the table if needed.
  Works with both PostgreSQL and SQLite.
  """
  def create_table_if_needed(repo) do
    adapter = repo.__adapter__()

    migration =
      case adapter do
        Ecto.Adapters.Postgres ->
          """
          CREATE TABLE IF NOT EXISTS #{@table_name} (
            time TIMESTAMPTZ NOT NULL,
            message TEXT NOT NULL,
            meta JSONB
          )
          """

        Ecto.Adapters.SQLite3 ->
          """
          CREATE TABLE IF NOT EXISTS #{@table_name} (
            time DATETIME NOT NULL,
            message TEXT NOT NULL,
            meta TEXT CHECK (json_valid(meta) OR meta IS NULL)
          )
          """
      end

    try do
      {status, result} = repo.query(migration, [], log: false)
      IO.puts("Created successfully: status=#{inspect(status)} result=#{inspect(result)}")
    rescue
      e ->
        IO.puts(:strderr, "error while creating the logs table: #{inspect(e)}")
        raise e
    end

    :ok
  end
end
