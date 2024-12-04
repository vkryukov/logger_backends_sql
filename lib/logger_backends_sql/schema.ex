defmodule LoggerBackends.SQL.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "logs" do
    field(:time, :utc_datetime_usec)
    field(:level, :string)
    field(:message, :string)
    field(:metadata, :map)
  end

  def changeset(log_entry \\ %__MODULE__{}, attrs) do
    log_entry
    |> cast(attrs, [:time, :level, :message, :metadata])
    |> validate_required([:time, :message])
  end
end
