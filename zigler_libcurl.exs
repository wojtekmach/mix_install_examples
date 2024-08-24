Mix.install([
  {:zigler, "~> 0.13"}
])

Logger.configure(level: :warning)

defmodule Main do
  use Zig,
    otp_app: :zigler,
    c: [link_lib: {:system, "curl"}]

  ~Z"""
  const std = @import("std");
  const curl = @cImport({
    @cInclude("curl/curl.h");
  });

  pub fn example() void {
    const c: *curl.CURL = curl.curl_easy_init().?;
    _ = curl.curl_easy_setopt(c, curl.CURLOPT_USERAGENT, "libcurl");
    _ = curl.curl_easy_setopt(c, curl.CURLOPT_URL, "https://httpbin.org/user-agent");
    _ = curl.curl_easy_perform(c);
  }
  """

  def main do
    example()
  end
end

Main.main()
