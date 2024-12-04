defmodule LoggerBackends.SQL.Migrations.CreateLogsTable do
  use Ecto.Migration

  def change do
    create table(:logs) do
      add :level, :string
      add :message, :text
      add :metadata, :map
      add :time, :utc_datetime
    end
  end
end
