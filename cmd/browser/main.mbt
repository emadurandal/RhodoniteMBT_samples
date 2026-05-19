#external
type Document

extern "js" fn document() -> Document =
  #| () => globalThis.document

extern "js" fn query_canvas(
  document : Document,
  selector : String,
) -> @objects.HTMLCanvasElement =
  #| (document, selector) => {
  #|   const canvas = document.querySelector(selector);
  #|   if (!canvas) throw new Error(`Canvas not found: ${selector}`);
  #|   return canvas;
  #| }

async fn main {
  let canvas = query_canvas(document(), "#rhodonite-canvas")
  ignore(
    @rhodonite_browser.run_single_canvas_platform(
      canvas,
      @rhodonite_browser.PlatformApp::default_engine(fn(engine) {
        @cube.install_rotating_cube(engine)
      }),
      @rhodonite_browser.PlatformOptions::render_loop(),
    ),
  )
}
