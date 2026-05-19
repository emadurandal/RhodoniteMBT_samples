import {
	Engine,
	Phase,
	PlatformApp,
	PlatformOptions,
	runBrowserWebGpuCanvasDemo,
	runSingleCanvasPlatform,
	type FrameState,
} from "rhodonite-mbt";
import "./style.css";

const uniformByteSize = 16;

const shaderSource = /* wgsl */ `
struct FrameUniforms {
  time: f32,
  aspect: f32,
  _pad0: f32,
  _pad1: f32,
};

@group(0) @binding(0)
var<uniform> frame: FrameUniforms;

struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

fn cubePosition(index: u32) -> vec3<f32> {
  var p = array<vec3<f32>, 36>(
    vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0),
    vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0), vec3<f32>(-1.0,  1.0,  1.0),
    vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0),
    vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0), vec3<f32>( 1.0,  1.0, -1.0),
    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0, -1.0,  1.0), vec3<f32>(-1.0,  1.0,  1.0),
    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>(-1.0,  1.0, -1.0),
    vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>( 1.0,  1.0, -1.0),
    vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0), vec3<f32>( 1.0,  1.0,  1.0),
    vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0),
    vec3<f32>(-1.0,  1.0,  1.0), vec3<f32>( 1.0,  1.0, -1.0), vec3<f32>(-1.0,  1.0, -1.0),
    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0,  1.0),
    vec3<f32>(-1.0, -1.0, -1.0), vec3<f32>( 1.0, -1.0,  1.0), vec3<f32>(-1.0, -1.0,  1.0)
  );
  return p[index];
}

@vertex
fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOut {
  let p = cubePosition(vertexIndex);
  let cy = cos(frame.time);
  let sy = sin(frame.time);
  let cx = cos(frame.time * 0.7);
  let sx = sin(frame.time * 0.7);
  let ry = vec3<f32>(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
  let rx = vec3<f32>(ry.x, ry.y * cx - ry.z * sx, ry.y * sx + ry.z * cx);
  let depth = 4.0 - rx.z;
  let f = 1.35;
  var out: VertexOut;
  out.position = vec4<f32>(rx.x * f / max(frame.aspect, 0.01), rx.y * f, depth * 0.55, depth);
  out.color = abs(normalize(p));
  return out;
}

@fragment
fn fragmentMain(input: VertexOut) -> @location(0) vec4<f32> {
  return vec4<f32>(input.color * 0.85 + vec3<f32>(0.15, 0.18, 0.22), 1.0);
}
`;

class CubeRenderer {
	private pipeline: GPURenderPipeline | undefined;
	private uniformBuffer: GPUBuffer | undefined;
	private bindGroup: GPUBindGroup | undefined;
	private readonly uniformValues = new Float32Array(4);

	render(engine: Engine, frame: FrameState): void {
		if (!frame.surface.active) {
			return;
		}
		this.initialize(engine.device, engine.format);
		if (
			this.pipeline === undefined ||
			this.uniformBuffer === undefined ||
			this.bindGroup === undefined
		) {
			return;
		}

		this.uniformValues[0] = frame.elapsedSeconds;
		this.uniformValues[1] = frame.surface.width / frame.surface.height;
		engine.queue.writeBuffer(this.uniformBuffer, 0, this.uniformValues);

		const encoder = engine.device.createCommandEncoder();
		const pass = encoder.beginRenderPass({
			colorAttachments: [
				{
					view: engine.context.getCurrentTexture().createView(),
					clearValue: { r: 0.05, g: 0.07, b: 0.1, a: 1 },
					loadOp: "clear",
					storeOp: "store",
				},
			],
		});
		pass.setPipeline(this.pipeline);
		pass.setBindGroup(0, this.bindGroup);
		pass.draw(36);
		pass.end();
		engine.queue.submit([encoder.finish()]);
	}

	private initialize(device: GPUDevice, format: GPUTextureFormat): void {
		if (this.pipeline !== undefined) {
			return;
		}
		const shader = device.createShaderModule({ code: shaderSource });
		const pipeline = device.createRenderPipeline({
			layout: "auto",
			vertex: { module: shader, entryPoint: "vertexMain" },
			fragment: {
				module: shader,
				entryPoint: "fragmentMain",
				targets: [{ format }],
			},
			primitive: { topology: "triangle-list", cullMode: "back" },
		});
		const uniformBuffer = device.createBuffer({
			size: uniformByteSize,
			usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
		});
		this.pipeline = pipeline;
		this.uniformBuffer = uniformBuffer;
		this.bindGroup = device.createBindGroup({
			layout: pipeline.getBindGroupLayout(0),
			entries: [
				{
					binding: 0,
					resource: { buffer: uniformBuffer, offset: 0, size: uniformByteSize },
				},
			],
		});
	}
}

function resizeCanvasToDisplaySize(canvas: HTMLCanvasElement): void {
	const ratio = window.devicePixelRatio || 1;
	const width = Math.max(1, Math.floor(canvas.clientWidth * ratio));
	const height = Math.max(1, Math.floor(canvas.clientHeight * ratio));
	if (canvas.width !== width || canvas.height !== height) {
		canvas.width = width;
		canvas.height = height;
	}
}

runBrowserWebGpuCanvasDemo({
	canvasId: "rhodonite-canvas",
	initialize: async (canvas) => {
		resizeCanvasToDisplaySize(canvas);
		window.addEventListener("resize", () => resizeCanvasToDisplaySize(canvas));
		await runSingleCanvasPlatform(
			canvas,
			PlatformApp.defaultEngine((engine) => {
				const renderer = new CubeRenderer();
				engine.addPhaseHandler(Phase.Render, (engine, frame) => {
					resizeCanvasToDisplaySize(canvas);
					renderer.render(engine, frame);
				});
				engine.requestContinuousRender("rotating-cube");
			}),
			PlatformOptions.renderLoop(),
		);
	},
});
