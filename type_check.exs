Mix.install([
  {:type_check, "~> 0.10.0"}
])

ExUnit.start()

defmodule User do
  use TypeCheck
  defstruct [:name, :age]

  @type! t :: %User{name: binary, age: integer}
end

defmodule AgeCheck do
  use TypeCheck

  @spec! user_older_than?(User.t(), integer) :: boolean
  def user_older_than?(user, age) do
    user.age >= age
  end
end

defmodule TypeCheckTest do
  use ExUnit.Case, async: true

  test "passes type check" do
    assert AgeCheck.user_older_than?(%User{name: "Qqwy", age: 11}, 10)
  end

  test "doesn't pass type check" do
    assert_raise TypeCheck.TypeError, fn ->
      AgeCheck.user_older_than?("foobar", 42)
    end
  end
end
