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
  `:message`, and `:metadata`. If it's not provided, the default
  schema LoggerBackends.SQL.Schema is used.
  """

  @behaviour :gen_event

  defstruct level: nil, repo: nil, schema: nil

  @impl true
  def init(atom) when is_atom(atom) do
    config = Application.get_env(:logger, __MODULE__, [])

    case init(config, %__MODULE__{}) do
      {:error, reason} -> {:error, reason}
      state -> {:ok, state}
    end
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = Keyword.merge(Application.get_env(:logger, __MODULE__, []), opts)

    case init(config, %__MODULE__{}) do
      {:error, reason} -> {:error, reason}
      state -> {:ok, state}
    end
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    repo = Keyword.get(config, :repo)
    schema = Keyword.get(config, :schema, LoggerBackends.SQL.Schema)

    cond do
      !repo ->
        {:error, "no repo configured"}

      !schema ->
        {:error, "no schema configured"}

      # {:error, reason} = repo.aggregate(schema, :count) ->
      #   {:error, "incorrect repo or schema is down: #{inspect(reason)}"}

      true ->
        %{state | level: level, repo: repo, schema: schema}
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

      try do
        record =
          schema.changeset(%{
            time: timestamp,
            message: message,
            metadata: md |> serialize_metadata,
            level: Atom.to_string(level)
          })

        result = repo.insert(record, log: false)

        case result do
          {:ok, _} ->
            :ok

          {:error, changeset} ->
            raise "Error inserting log entry: #{inspect(changeset.errors)}"
        end
      rescue
        e ->
          raise e
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
