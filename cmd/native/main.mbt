async fn main {
  try {
    @sdl3.run_single_window_platform(
      "RhodoniteMBT rotating cube",
      960,
      540,
      @sdl3.PlatformApp::default_engine(fn(engine) {
        @cube.install_rotating_cube(engine)
      }),
      @sdl3.PlatformOptions::render_loop(),
      init_log="RhodoniteMBT_ex native sample",
    )
  } catch {
    _ => println("native sample failed")
  }
}
