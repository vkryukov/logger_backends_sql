defmodule LoggerBackends.SQL do
  @moduledoc """
  A logger backend for the `:logger_backends` package
  that logs messages to a SQL database.

  ## Options

      * `:level` - the level to be logged by this backend.
      Note that messages are filtered by the general
      `:level` configuration for the `:logger` application first.

      * `:repo` - the Ecto repo to be used to store the logs.

      * `:schema` - the Ecto schema to be used. This schema should
      have a changeset function that accepts a map with keys `:time`,
      `:message`, and `:meta`. If not provided, the default schema
      in `LoggerBackends.SQL.Schema` will be used.

      * `:table_name` - the table to be used to store the logs 
      for the default schema. It *must* have columns `time`, `message`,
      and `meta`, which are of types `utc_datetime_usec`, `string`, and
      `map`, respectively. If the table doesn't exist, it will be created.

      Note that the `:table_name` option is only used for the default schema,
      and it's a *compile-time* option. This means that if you want to change
      the table name, you need to change it in `config/config.exs` 
      and recompile the code.

      * `:path` - the path to the SQLite database file. This option is only
      used when the `:repo` option is not provided.
  """

  @behaviour :gen_event

  defstruct level: nil, repo: nil, schema: LoggerBackends.SQL.Schema, path: nil

  @impl true
  def init(atom) when is_atom(atom) do
    config = Application.get_env(:logger, __MODULE__, [])
    {:ok, init(config, %__MODULE__{})}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = Keyword.merge(Application.get_env(:logger, __MODULE__, []), opts)
    {:ok, init(config, %__MODULE__{})}
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    repo = Keyword.get(config, :repo)
    schema = Keyword.get(config, :schema, LoggerBackends.SQL.Schema)
    path = Keyword.get(config, :path)

    try do
      {:ok, _pid} = if path && !repo, do: LoggerBackends.SQL.Repo.start(path), else: {:ok, nil}
      repo = LoggerBackends.SQL.Repo

      if schema == LoggerBackends.SQL.Schema do
        LoggerBackends.SQL.Schema.create_table_if_needed(repo)
      end

      %{state | level: level, repo: repo, schema: schema}
    rescue
      e ->
        IO.puts(:stderr, "error creating the database: #{inspect(e)}")
        raise e
    end
  end

  @impl true
  def handle_event({_level, gl, {Logger, _, _, _}}, state)
      when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    %{level: log_level, repo: repo, schema: schema} = state

    if meet_level?(level, log_level) do
      message =
        case msg do
          msg when is_binary(msg) -> msg
          msg -> IO.iodata_to_binary(msg)
        end

      timestamp = to_utc_datetime(ts)

      record =
        schema.changeset(%{time: timestamp, message: message, meta: md |> serialize_metadata})

      case repo.insert(record, log: false) do
        {:ok, _} ->
          :ok

        {:error, changeset} ->
          IO.puts(:stderr, "Error inserting log entry: #{inspect(changeset.errors)}")
      end
    end

    {:ok, state}
  end

  @impl true
  def handle_event(:flush, state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  defp configure(options, state) do
    config = Keyword.merge(Application.get_env(:logger, __MODULE__, []), options)
    Application.put_env(:logger, __MODULE__, config)
    init(config, state)
  end

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp to_utc_datetime({{year, month, day}, {hour, minute, second, millisecond}}) do
    {:ok, naive} = NaiveDateTime.new(year, month, day, hour, minute, second, millisecond)
    DateTime.from_naive!(naive, "Etc/UTC")
  end

  defp serialize_metadata(metadata) do
    metadata
    |> Enum.map(fn {key, value} -> {key, serialize_value(value)} end)
    |> Enum.into(%{})
  end

  defp serialize_value(value) when is_pid(value), do: inspect(value)
  defp serialize_value(value) when is_port(value), do: inspect(value)
  defp serialize_value(value) when is_reference(value), do: inspect(value)
  defp serialize_value(value) when is_function(value), do: inspect(value)
  defp serialize_value(value) when is_atom(value), do: to_string(value)
  defp serialize_value(value) when is_list(value), do: Enum.map(value, &serialize_value/1)

  defp serialize_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.map(&serialize_value/1)

  defp serialize_value(value) when is_map(value),
    do: Map.new(value, fn {k, v} -> {k, serialize_value(v)} end)

  defp serialize_value(value), do: value
end
