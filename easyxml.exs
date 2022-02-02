Mix.install([
  {:easyxml, github: "wojtekmach/easyxml"}
])

EasyXML.parse!("""
<?xml version="1.0" encoding="UTF-8"?>
<points>
  <point x="1" y="2"/>
  <point x="3" y="4"/>
  <point x="5" y="6"/>
</points>
""")
|> IO.inspect(syntax_colors: [string: :green])
