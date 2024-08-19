Mix.install([
  {:zigler, "~> 0.13"}
])

Logger.configure(level: :warning)

defmodule Main do
  use Zig, otp_app: :zigler

  ~Z"""
  pub fn add_f64(value1: f64, value2: f64) f64 {
    return value1 + value2;
  }
  """

  def main do
    IO.inspect(add_f64(1.1, 2.2))
  end
end

Main.main()
