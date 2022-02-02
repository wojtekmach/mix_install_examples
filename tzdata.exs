Mix.install([
  {:tzdata, "~> 1.0"}
])

Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

DateTime.now!("Europe/Warsaw")
|> IO.inspect()
