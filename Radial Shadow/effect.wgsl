%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
  shadow_color : vec3<f32>,
  shadow_opacity : f32,
  sharpness : f32,
  horizontal_center : f32,
  vertical_center : f32,
  horizontal_scale : f32,
  vertical_scale : f32,
  horizontal_offset : f32,
  vertical_offset : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
  let object_color = textureSample(textureFront, samplerFront, input.fragUV);

  if (shaderParams.shadow_opacity <= 0.0) {
    var early_output : FragmentOutput;
    early_output.color = object_color;
    return early_output;
  }

  let layoutSize = abs(c3Params.layoutEnd - c3Params.layoutStart);
  let texelSize = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;
  let pixelSize = vec2<f32>(texelSize.x, -texelSize.y);
  let object_size = c3Params.srcOriginEnd - c3Params.srcOriginStart;
  let center = c3Params.srcOriginStart + object_size * vec2<f32>(shaderParams.horizontal_center, shaderParams.vertical_center);

  var offset_uv = input.fragUV;
  let offset_vec = vec2<f32>(-shaderParams.horizontal_offset * pixelSize.x, shaderParams.vertical_offset * pixelSize.y);

  if (shaderParams.horizontal_offset != 0.0 || shaderParams.vertical_offset != 0.0) {
    offset_uv = offset_uv + offset_vec;
  }

  let scale_vec = vec2<f32>(shaderParams.horizontal_scale, shaderParams.vertical_scale);
  let base_coord = center + (offset_uv - center) / scale_vec;

  let src_half_size = object_size * 0.5;
  let dist_vec = abs(base_coord - center);
  let dist = length(dist_vec / src_half_size);

  let smooth_range = mix(0.5, 0.001, min(shaderParams.sharpness, 1.0));
  var circle_alpha = 1.0 - smoothstep(1.0 - smooth_range, 1.0 + smooth_range, dist);

  if (shaderParams.sharpness > 0.0) {
    let clamped_sharpness = min(shaderParams.sharpness, 1.0);
    let sharpness_cutoff = 0.5 + clamped_sharpness * 0.5;
    circle_alpha = mix(circle_alpha, select(0.0, 1.0, circle_alpha >= sharpness_cutoff), clamped_sharpness);
  }

  if (circle_alpha <= 0.0) {
    var early_output : FragmentOutput;
    early_output.color = object_color;
    return early_output;
  }

  let shadow_intensity = shaderParams.shadow_opacity * circle_alpha;
  let shadow_rgb = shaderParams.shadow_color * shadow_intensity;
  let final_color = object_color + vec4<f32>(shadow_rgb, shadow_intensity) * (1.0 - object_color.a);

  var output_result : FragmentOutput;
  output_result.color = final_color;
  return output_result;
}