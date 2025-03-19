Mix.install([{:protox, "~> 2.0"}])

defmodule Messages do
  use Protox,
    namespace: Messages,
    schema: """
    syntax = "proto3";

    message Tag {
      string name = 1;
    }

    message Post {
      string title = 1;
      repeated Tag tags = 2;
    }
    """
end

defmodule Main do
  def main do
    tag = %Messages.Tag{name: "elixir"}
    post = %Messages.Post{title: "Welcome", tags: [tag]}
    {:ok, iodata, _size} = Protox.encode(post)
    dbg(Protox.decode(IO.iodata_to_binary(iodata), Messages.Post))
  end
end

Main.main()
