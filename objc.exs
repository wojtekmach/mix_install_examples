Mix.install([
  {:objc, github: "wojtekmach/objc"}
])

defmodule HelloObjc.MixProject do
  use Mix.Project

  def project do
    [
      app: :hello_objc,
      version: "1.0.0"
    ]
  end
end

defmodule HelloObjC do
  use ObjC, compile: "-lobjc -framework AppKit"

  defobjc(:hello, 0, ~S"""
  #import "AppKit/AppKit.h"

  extern int erl_drv_steal_main_thread(char *name, ErlNifTid *dtid, void* (*func)(void*), void* arg, ErlNifThreadOpts *opts);
  extern int erl_drv_stolen_main_thread_join(ErlNifTid tid, void **respp);

  ErlNifTid hello_thread;

  void *hello_main_loop(void * _unused)
  {
      [NSAutoreleasePool new];
      [NSApplication sharedApplication];
      [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
      [NSApp activateIgnoringOtherApps:YES];
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:@"Hello from ObjC!"];
      [alert addButtonWithTitle:@"Ok"];
      [alert runModal];
      return NULL;
  }

  static ERL_NIF_TERM hello(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
  {
      erl_drv_steal_main_thread((char *)"hello", &hello_thread, hello_main_loop, (void *) NULL,NULL);
      erl_drv_stolen_main_thread_join(hello_thread, NULL);
      return enif_make_atom(env, "ok");
  }
  """)
end

:ok = HelloObjC.hello()
