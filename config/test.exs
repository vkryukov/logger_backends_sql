import Config

config :logger_backends_sql,
       LoggerBackends.SQL.TestRepo,
       database: "test.sqlite",
       pool_size: 1,
       pool: Ecto.Adapters.SQL.Sandbox,
       priv: "priv",
       log: false

config :logger_backends_sql, ecto_repos: [LoggerBackends.SQL.TestRepo]

config :logger,
  level: :debug,
  default_handler: false

config :logger, LoggerBackends.SQL,
  repo: LoggerBackends.SQL.TestRepo,
  level: :info
