Mix.install([
  {:saxy, "~> 1.4"}
])

xml =
  Saxy.XML.element("people", [], [
    Saxy.XML.element("person", [name: "Alice"], []),
    Saxy.XML.element("person", [name: "Bob"], [])
  ])
  |> Saxy.encode!()
  |> IO.inspect(label: :encoded)

{:ok, decoded} = Saxy.SimpleForm.parse_string(xml)
IO.inspect(decoded, label: :decoded)
