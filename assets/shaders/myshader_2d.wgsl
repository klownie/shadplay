#import bevy_sprite::mesh2d_view_bindings::globals
#import shadplay::shader_utils::common::{NEG_HALF_PI, shader_toy_default, rotate2D, TWO_PI}
#import bevy_render::view::View
#import bevy_sprite::mesh2d_vertex_output::VertexOutput

@group(0) @binding(0) var<uniform> view: View;

@group(2) @binding(100) var<uniform> mouse: YourShader2D;
struct YourShader2D{
    pos : vec2f,
}

const EPS = 0.00005;
const FAR = 500.0;
const PI = 3.1415926;
const SPEED = 0.1;

fn rotX(p: vec3f, a: f32) -> vec3f { let r = p.yz * cos(a) + vec2f(-p.z, p.y) * sin(a); return vec3f(p.x, r); }
fn rotY(p: vec3f, a: f32) -> vec3f { let r = p.xz * cos(a) + vec2f(-p.z, p.x) * sin(a); return vec3f(r.x, p.y, r.y); }
fn rotM(p: vec3f, m: vec2f) -> vec3f { return rotY(rotX(p, -PI * m.y), 2 * PI * m.x); }

fn normal(p: vec3f) -> vec3f {
    let k = vec2f(1.,-1.);
    return normalize(
        k.xyy*map(p + k.xyy*EPS) +
        k.yyx*map(p + k.yyx*EPS) +
        k.yxy*map(p + k.yxy*EPS) +
        k.xxx*map(p + k.xxx*EPS)    );
}

fn march(ro: vec3f, rd: vec3f) -> vec3f {
    var p: vec3f;
    var s: f32;
    for (var i = 0; i < 99; i++) {
        p = ro + s * rd;
        let ds = map(p);
        s += ds;
        if (ds < EPS|| s > FAR) { break; }
    }
    return p;
}

fn sdSphere(p: vec3f, r: f32) -> f32 {
    return length(p) - r;
}

fn sdBox(p: vec3f, b: vec3f) -> f32 {
  let q = abs(p) - b;
  return length(max(q, vec3f(0.))) + min(max(q.x, max(q.y, q.z)), 0.);
}

fn opSubtract(d1: f32, d2: f32) -> f32 {
    return max(d1, -d2);
}

fn opSmoothUnion(d1: f32, d2: f32, k: f32) -> f32 {
  let h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0., 1.);
  return mix(d2, d1, h) - k * h * (1. - h);
}

fn opLimArray(p: vec3f, c: f32, lim: vec3f) -> vec3f {
    return p - c * clamp(round(p / c), -lim, lim);
}

fn opInfArray(p: vec3f, c: vec3f) -> vec3f {
  return p - c * round(p / c);
}

fn map(p0: vec3f) -> f32 {
    let p = opInfArray(p0, vec3f(17.));
    var r = opSmoothUnion(sdBox(p, vec3f(1)), sdSphere(p + sin(globals.time) * 2.2 , 1.), 3.);
//    r = opSubtract(r, sdBox(p - 1 ,vec3f(1.)));
    return r;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {

    let t = globals.time;

    var uv = (in.uv * 2.0) - 1.0;
    let res = view.viewport.zw;
    uv.x *= res.x / res.y;

    var ro = vec3f(0, 0, 12);
    var rd = normalize(vec3f(uv, -2));

    let rot = vec2f(sin(globals.time) * 0.1,sin(globals.time) * 0.05);
    ro = rotM(ro, rot );
    rd = rotM(rd, rot );

    let p = march(ro, rd);
    let n = normal(p);
    let l = normalize(vec3f(-1,0,1));

    let bg = vec3f(0);
    var col = vec3f(n*.5+.5);
    col = mix(col, bg, map(p));

    return vec4f(col, 1.0);
}