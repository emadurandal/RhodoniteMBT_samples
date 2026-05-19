let uniform_byte_size : UInt64 = 16UL

let shader_source =
  #|struct FrameUniforms {
  #|  time: f32,
  #|  aspect: f32,
  #|  _pad0: f32,
  #|  _pad1: f32,
  #|};
  #|
  #|@group(0) @binding(0)
  #|var<uniform> frame: FrameUniforms;
  #|
  #|struct VertexOut {
  #|  @builtin(position) position: vec4<f32>,
  #|  @location(0) color: vec3<f32>,
  #|};
  #|
  #|fn cube_position(index: u32) -> vec3<f32> {
  #|  var p = array<vec3<f32>, 36>(
  #|    vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0),
  #|    vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0), vec3<f32>(-1.0,  1.0,  1.0),
  #|    vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0),
  #|    vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0), vec3<f32>( 1.0,  1.0, -1.0),
  #|    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>(-1.0,  1.0,  1.0),
  #|    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>(-1.0,  1.0, -1.0),
  #|    vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>( 1.0,  1.0, -1.0),
  #|    vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0), vec3<f32>( 1.0,  1.0,  1.0),
  #|    vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0),
  #|    vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0),
  #|    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0,  1.0),
  #|    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>(-1.0, -1.0,  1.0)
  #|  );
  #|  return p[index];
  #|}
  #|
  #|@vertex
  #|fn vertexMain(@builtin(vertex_index) vertex_index: u32) -> VertexOut {
  #|  let p = cube_position(vertex_index);
  #|  let cy = cos(frame.time);
  #|  let sy = sin(frame.time);
  #|  let cx = cos(frame.time * 0.7);
  #|  let sx = sin(frame.time * 0.7);
  #|  let ry = vec3<f32>(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
  #|  let rx = vec3<f32>(ry.x, ry.y * cx - ry.z * sx, ry.y * sx + ry.z * cx);
  #|  let depth = 4.0 - rx.z;
  #|  let f = 1.35;
  #|  var out: VertexOut;
  #|  out.position = vec4<f32>(rx.x * f / max(frame.aspect, 0.01), rx.y * f, depth * 0.55, depth);
  #|  out.color = abs(normalize(p));
  #|  return out;
  #|}
  #|
  #|@fragment
  #|fn fragmentMain(input: VertexOut) -> @location(0) vec4<f32> {
  #|  return vec4<f32>(input.color * 0.85 + vec3<f32>(0.15, 0.18, 0.22), 1.0);
  #|}

priv struct CubeRenderer {
  mut initialized : Bool
  mut pipeline : @wgpu.GPURenderPipeline?
  mut uniform_buffer : @wgpu.GPUBuffer?
  mut bind_group : @wgpu.GPUBindGroup?
  uniform_bytes : FixedArray[Byte]
}

fn CubeRenderer::new() -> CubeRenderer {
  {
    initialized: false,
    pipeline: None,
    uniform_buffer: None,
    bind_group: None,
    uniform_bytes: FixedArray::make(uniform_byte_size.to_int(), (0 : Byte)),
  }
}

fn CubeRenderer::initialize(
  self : CubeRenderer,
  device : @wgpu.GPUDevice,
  format : String,
) -> Unit {
  if self.initialized {
    return
  }
  let shader = device.create_shader_module(shader_source)
  let pipeline = device.create_render_pipeline(
    @wgpu.GPURenderPipelineDescriptor::{
      vertex: shader,
      fragment: shader,
      topology: TriangleList,
      formats: [format],
      vertex_buffers: [],
      depth_stencil_format: None,
    },
  )
  let uniform_buffer = device.create_buffer(
    uniform_byte_size,
    @wgpu.GPU_BUFFER_USAGE_UNIFORM | @wgpu.GPU_BUFFER_USAGE_COPY_DST,
  )
  let layout = pipeline.get_bind_group_layout(0U)
  let bind_group = device.create_bind_group(
    @wgpu.GPUBindGroupDescriptor::{
      layout,
      entries: [
        @wgpu.GPUBindGroupEntry::{
          binding: 0U,
          resource: BufferBinding(
            @wgpu.GPUBufferBinding::{
              buffer: uniform_buffer,
              offset: 0UL,
              size: uniform_byte_size,
            },
          ),
        },
      ],
    },
  )
  self.pipeline = Some(pipeline)
  self.uniform_buffer = Some(uniform_buffer)
  self.bind_group = Some(bind_group)
  self.initialized = true
}

fn CubeRenderer::render(
  self : CubeRenderer,
  engine : @app.Engine,
  frame : @app.FrameState,
) -> Unit {
  if !frame.surface_active() {
    return
  }
  let (device, canvas_context, format, queue) = engine.gpu_context().get()
  self.initialize(device, format)
  @writes.put_f32_le(self.uniform_bytes, 0, frame.elapsed_seconds())
  @writes.put_f32_le(
    self.uniform_bytes,
    4,
    frame.surface_width().to_double() / frame.surface_height().to_double(),
  )
  let uniform_buffer = match self.uniform_buffer {
    Some(buffer) => buffer
    None => return
  }
  queue.write_buffer_from_fixed_array(uniform_buffer, 0UL, self.uniform_bytes)
  let texture = canvas_context.get_current_texture()
  let view = texture.create_view()
  let encoder = device.create_command_encoder()
  let pass = encoder.begin_render_pass(
    @wgpu.GPURenderPassDescriptor::{
      color_attachments: [
        Some(
          @wgpu.GPURenderPassColorAttachment::{
            view,
            clear_value: Some(@gpu.GPUColor::{ r: 0.05, g: 0.07, b: 0.1, a: 1.0 }),
            load_op: Clear,
            store_op: Store,
          },
        ),
      ],
      depth_stencil_attachment: None,
    },
  )
  match (self.pipeline, self.bind_group) {
    (Some(pipeline), Some(bind_group)) => {
      pass.set_pipeline(pipeline)
      pass.set_bind_group(0U, bind_group, [])
      pass.draw(36)
    }
    _ => ()
  }
  pass.end()
  let command_buffer = encoder.finish()
  queue.submit(command_buffer)
  canvas_context.present()
}

pub fn install_rotating_cube(engine : @app.Engine) -> Bool {
  let renderer = CubeRenderer::new()
  engine.add_phase_handler(
    @app.phase_render(),
    fn(engine, frame) { renderer.render(engine, frame) },
  )
  engine.request_continuous_render("rotating-cube")
  true
}
