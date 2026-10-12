# Usage: ANTHROPIC_API_KEY=... elixir req_llm.exs
Mix.install([
  {:req_llm, "~> 1.28"}
])

ReqLLM.generate_text!("anthropic:claude-sonnet-5-5", "Hello world")
|> IO.puts()
