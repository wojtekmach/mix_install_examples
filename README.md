# MixInstallExamples

A collection of simple Elixir scripts that are using
[`Mix.install/2`](https://hexdocs.pm/mix/Mix.html#install/2). (Requires Elixir v1.12+)

## Example

Let's run the example [`benchee.exs`](benchee.exs) script of the excellent
[Benchee](https://github.com/bencheeorg/benchee) benchmarking library.

```
$ git clone https://github.com/wojtekmach/mix_install_examples.git
$ cd mix_install_examples
$ cat benchee.exs
```

```elixir
Mix.install([
  {:benchee, "~> 1.0"}
])

list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 10,
  memory_time: 2
)
```

```
$ elixir benchee.exs
Operating System: macOS
CPU Information: Apple M1
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.14.0-dev
Erlang 25.0-rc3

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 2 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 28 s

Benchmarking flat_map ...
Benchmarking map.flatten ...

Name                  ips        average  deviation         median         99th %
flat_map           4.44 K      225.22 μs     ±2.98%         224 μs      246.52 μs
map.flatten        2.68 K      372.56 μs    ±24.96%      374.13 μs      560.40 μs

Comparison:
flat_map           4.44 K
map.flatten        2.68 K - 1.65x slower +147.34 μs

Memory usage statistics:

Name           Memory usage
flat_map             625 KB
map.flatten       781.25 KB - 1.25x memory usage +156.25 KB

**All measurements for memory usage were the same**
```
