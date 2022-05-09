Mix.install([
  {:html5ever, "~> 0.13.0"}
])

html = """
<!doctype html>
<html>
<body><h1>Hello world</h1></body>
</html>
"""

IO.inspect(Html5ever.parse(html))
