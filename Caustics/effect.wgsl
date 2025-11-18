%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
  caustic_color : vec3<f32>,
  speed : f32,
  horizontal_scale : f32,
  vertical_scale : f32,
  threshold : f32,
  sharpness : f32,
  pixel_size : f32,
  glow_intensity : f32,
  glow_threshold : f32,
  opacity_variation : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

fn calculateCaustic(k_param : ptr<function, vec4<f32>>, matrix_param : mat3x3<f32>, scale_param : f32) -> f32 {
  let scaled_matrix = matrix_param * scale_param;
  let k_value = *k_param;
  let transformed_coords = vec3<f32>(k_value.x, k_value.y, k_value.w) * scaled_matrix;
  (*k_param) = vec4<f32>(transformed_coords.x, transformed_coords.y, k_value.z, transformed_coords.z);
  return length(0.5 - fract((*k_param).xyw));
}

fn simpleHash(p : vec2<f32>) -> f32 {
  return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

fn smoothNoise(p : vec2<f32>) -> f32 {
  let i = floor(p);
  let f = fract(p);
  let a = simpleHash(i);
  let b = simpleHash(i + vec2<f32>(1.0, 0.0));
  let c = simpleHash(i + vec2<f32>(0.0, 1.0));
  let d = simpleHash(i + vec2<f32>(1.0, 1.0));
  let u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
  let screen_coord = c3_getLayoutPos(input.fragUV);

  if (shaderParams.threshold >= 1.0 && shaderParams.glow_intensity <= 0.0) {
    var early_output : FragmentOutput;
    early_output.color = textureSample(textureFront, samplerFront, input.fragUV);
    return early_output;
  }

  let pixel_size_value = shaderParams.pixel_size;
  var current_coord = screen_coord;
  if (pixel_size_value > 0.0) {
    current_coord = floor(current_coord / pixel_size_value) * pixel_size_value;
  }

  let current_time = c3Params.seconds * shaderParams.speed;

  let caustic_matrix = mat3x3<f32>(
    -2.0, -1.0, 2.0,
     3.0, -2.0, 1.0,
     1.0,  2.0, 2.0
  );

  var caustic_params = vec4<f32>(current_coord.x, current_coord.y, 0.0, current_time);
  let scaled_coords = vec2<f32>(caustic_params.x / shaderParams.horizontal_scale, caustic_params.y / shaderParams.vertical_scale) / 100.0;
  caustic_params = vec4<f32>(scaled_coords, caustic_params.z, caustic_params.w);

  let min_value_1 = min(calculateCaustic(&caustic_params, caustic_matrix, 0.5), calculateCaustic(&caustic_params, caustic_matrix, 0.4));
  let min_value_2 = min(min_value_1, calculateCaustic(&caustic_params, caustic_matrix, 0.3));

  let caustic_intensity = 1.0 - pow(min_value_2, 7.0) * 25.0;
  var base_intensity = 1.0 - smoothstep(shaderParams.threshold, shaderParams.threshold + 0.3, caustic_intensity);
  var glow_layer = 1.0 - smoothstep(shaderParams.glow_threshold, shaderParams.glow_threshold + 0.6, caustic_intensity);
  glow_layer *= shaderParams.glow_intensity;

  if (shaderParams.sharpness > 0.0) {
    let sharpness_cutoff = 0.5 + shaderParams.sharpness * 0.5;
    base_intensity = mix(base_intensity, step(sharpness_cutoff, base_intensity), shaderParams.sharpness);
    glow_layer = mix(glow_layer, step(sharpness_cutoff, glow_layer), shaderParams.sharpness);
  }

  let original_color = textureSample(textureFront, samplerFront, input.fragUV);

  var final_alpha = base_intensity * original_color.a;

  if (shaderParams.opacity_variation > 0.0) {
    let scale_factor = max(shaderParams.horizontal_scale, shaderParams.vertical_scale);
    let noise_scale = 0.005 / scale_factor;
    let noise = smoothNoise(current_coord * noise_scale + current_time * 0.05);
    let variation = mix(1.0, 1.0 - noise, shaderParams.opacity_variation);
    final_alpha *= variation;
  }

  let base_color = shaderParams.caustic_color * final_alpha;
  let glow_color = vec3<f32>(1.0) * glow_layer * final_alpha;
  let final_color = base_color + glow_color;

  var output_result : FragmentOutput;
  output_result.color = vec4<f32>(final_color, final_alpha);
  return output_result;
}