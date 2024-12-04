ExUnit.start()
LoggerBackends.SQL.TestRepo.start_link()
{:ok, _} = LoggerBackends.add(LoggerBackends.SQL)
