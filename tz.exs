Mix.install([
  {:tz, "~> 0.26"}
])

Calendar.put_time_zone_database(Tz.TimeZoneDatabase)

DateTime.now!("Europe/Warsaw")
|> IO.inspect()
