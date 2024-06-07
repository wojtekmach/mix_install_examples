# $ docker run -e "ACCEPT_EULA=Y" -e 'MSSQL_SA_PASSWORD=Secret1@' -p 1433:1433 \
#     --platform linux/amd64 \
#     mcr.microsoft.com/mssql/server:2022-latest
Mix.install([
  {:tds, "~> 2.3"}
])

{:ok, pid} =
  Tds.start_link(
    username: "sa",
    password: "Secret1@",
    database: "master",
    port: 1433
  )

dbg(Tds.query!(pid, "SELECT GETDATE()", []))
