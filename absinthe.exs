Mix.install([
  :absinthe
])

defmodule ContentTypes do
  use Absinthe.Schema.Notation

  object(:post) do
    field(:id, :id)
    field(:title, :string)
    field(:body, :string)
  end
end

defmodule Schema do
  use Absinthe.Schema

  import_types(ContentTypes)

  query do
    field :posts, list_of(:post) do
      resolve(fn _parent, _args, _context ->
        posts = [
          %{
            id: 1,
            title: "Foo",
            body: "Bar"
          }
        ]

        {:ok, posts}
      end)
    end
  end
end

Absinthe.run("query { posts { id, title } }", Schema)
|> IO.inspect()
