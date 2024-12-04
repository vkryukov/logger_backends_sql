defmodule Mix.Tasks.LoggerBackendsSql.Gen.Migration do
  use Mix.Task

  @shortdoc "Generates a migration for the logs table"
  @migration_source Path.join(
                      :code.priv_dir(:logger_backends_sql),
                      "migrations/20241201000000_create_logs_table.exs"
                    )

  def run(_args) do
    timestamp = timestamp()
    target_path = Path.join("priv/repo/migrations", "#{timestamp}_create_logs_table.exs")

    @migration_source
    |> File.read!()
    |> String.replace(
      "LoggerBackends.SQL.Migrations.CreateLogsTable",
      "#{Mix.Project.get().project()[:app]}.Repo.Migrations.CreateLogsTable"
    )
    |> then(&Mix.Generator.create_file(target_path, &1))

    Mix.shell().info("Created #{target_path}")
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
