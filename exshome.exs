root_folder = Path.join(System.tmp_dir(), ".exshome")

Application.put_all_env(
  exshome: [
    {:ecto_repos, [Exshome.Repo]},
    {:on_stop, fn _ -> System.halt(1) end},
    {:root_folder, root_folder},
    {Exshome.Application,
     [
       apps: [ExshomeClock],
       on_init: &Exshome.Release.migrate/0
     ]},
    {ExshomeWeb.Endpoint,
     [
       cache_static_manifest: {:exshome, "priv/static/cache_manifest.json"},
       http: [ip: {127, 0, 0, 1}, port: 5001],
       check_origin: false,
       server: true,
       live_view: [signing_salt: "aaaaaaaa"],
       secret_key_base: String.duplicate("a", 64),
       pubsub_server: Exshome.PubSub
     ]},
    {Exshome.Repo,
     [
       migration_primary_key: [name: :id, type: :binary_id],
       migration_timestamps: [type: :utc_datetime_usec],
       cache_size: -2000,
       database: Path.join([root_folder, "db", "exshome.db"])
     ]}
  ],
  phoenix: [json_library: Jason]
)

Calendar.put_time_zone_database(Tz.TimeZoneDatabase)

Mix.install([{:exshome, "0.1.7"}])

{:ok, _} = Application.ensure_all_started(:exshome)
System.no_halt(true)
