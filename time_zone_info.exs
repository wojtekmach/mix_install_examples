Mix.install([
  {:time_zone_info, "~> 0.6"}
])

Calendar.put_time_zone_database(TimeZoneInfo.TimeZoneDatabase)

DateTime.now!("Europe/Warsaw")
|> IO.inspect()
