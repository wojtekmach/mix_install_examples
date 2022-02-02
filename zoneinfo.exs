Mix.install([
  {:zoneinfo, "~> 0.1.0"}
])

Calendar.put_time_zone_database(Zoneinfo.TimeZoneDatabase)

DateTime.now!("Europe/Warsaw")
|> IO.inspect()
