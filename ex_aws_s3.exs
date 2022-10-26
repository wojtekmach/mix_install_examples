Mix.install(
  [
    {:ex_aws, "~> 2.3"},
    {:ex_aws_s3, "~> 2.3"},
    {:hackney, "~> 1.9"},
    {:jason, "~> 1.3"},
    {:sweet_xml, "~> 0.6"}
  ],
  config: [
    ex_aws: [
      access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}],
      secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}]
    ]
  ]
)

ExAws.S3.list_objects("my-bucket")
|> ExAws.stream!()
|> Enum.to_list()
|> IO.inspect()
