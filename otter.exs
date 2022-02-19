Mix.install([
  {:otter, github: "cocoa-xu/otter", ref: "ade4cb"}
])

defmodule Ctypes do
  import Otter

  # module level default shared library name/path
  @default_from (case :os.type() do
                   {:unix, :darwin} -> "libSystem.B.dylib"
                   {:unix, _} -> "libc.so"
                   {:win32, _} -> raise "Windows is not supported yet"
                 end)

  # module level default dlopen mode
  @default_mode :RTLD_NOW

  extern(printf(:s32, c_ptr))
end

{:ok, _} = Ctypes.printf("Hello, World!\n")
