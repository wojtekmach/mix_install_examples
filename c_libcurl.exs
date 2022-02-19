Mix.install([
  {:c, github: "wojtekmach/c"}
])

defmodule Curl.MixProject do
  use Mix.Project

  def project do
    [
      app: :curl,
      version: "1.0.0"
    ]
  end
end

defmodule Main do
  def main do
    Curl.test()
  end
end

defmodule Curl do
  use C, compile: "-lcurl"

  # Based on https://curl.se/libcurl/c/simple.html

  defc(:test, 0, ~S"""
  #include <curl/curl.h>

  static ERL_NIF_TERM test(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
  {
    CURL *curl;
    CURLcode res;

    curl = curl_easy_init();

    if (!curl) {
      enif_raise_exception(env, enif_make_string(env, "could not init curl", ERL_NIF_LATIN1));
      return -1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, "https://httpbin.org/json");

    /* Perform the request, res will get the return code */
    res = curl_easy_perform(curl);

    /* Check for errors */
    if (res != CURLE_OK) {
      fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
    }

    /* always cleanup */
    curl_easy_cleanup(curl);

    return enif_make_atom(env, "ok");
  }
  """)
end

Main.main()
