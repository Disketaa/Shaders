%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
  shadow_color : vec3<f32>,
  shadow_opacity : f32,
  angle : f32,
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
  if (shaderParams.shadow_opacity <= 0.0) {
    var early_output : FragmentOutput;
    early_output.color = textureSample(textureFront, samplerFront, input.fragUV);
    return early_output;
  }

  let layoutSize = abs(c3Params.layoutEnd - c3Params.layoutStart);
  let texelSize = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;
  let pixelSize = vec2<f32>(texelSize.x, -texelSize.y);

  let object_size = c3Params.srcOriginEnd - c3Params.srcOriginStart;
  let center = c3Params.srcOriginStart + object_size * vec2<f32>(shaderParams.horizontal_center, shaderParams.vertical_center);

  let object_color = textureSample(textureFront, samplerFront, input.fragUV);
  var shadow_sample = vec4<f32>(0.0);

  var offset_uv = input.fragUV;

  if (shaderParams.horizontal_offset != 0.0 || shaderParams.vertical_offset != 0.0) {
    offset_uv = input.fragUV + vec2<f32>(-shaderParams.horizontal_offset * pixelSize.x, shaderParams.vertical_offset * pixelSize.y);
  }

  var processed_coord = offset_uv;

  if (shaderParams.horizontal_scale != 1.0 || shaderParams.vertical_scale != 1.0) {
    processed_coord = center + (processed_coord - center) / vec2<f32>(shaderParams.horizontal_scale, shaderParams.vertical_scale);
  }

  if (shaderParams.angle != 0.0) {
    let rad = shaderParams.angle * 3.1415927 / 180.0;
    let cosA = cos(rad);
    let sinA = sin(rad);
    processed_coord = center + vec2<f32>(
      cosA * (processed_coord.x - center.x) - sinA * (processed_coord.y - center.y),
      sinA * (processed_coord.x - center.x) + cosA * (processed_coord.y - center.y)
    );
  }

  shadow_sample = textureSample(textureFront, samplerFront, processed_coord);

  if (shaderParams.sharpness > 0.0) {
    let clamped_sharpness = min(shaderParams.sharpness, 1.0);
    let sharpness_cutoff = 0.5 + clamped_sharpness * 0.5;
    shadow_sample.a = mix(shadow_sample.a, select(0.0, 1.0, shadow_sample.a >= sharpness_cutoff), clamped_sharpness);
  }

  if (shadow_sample.a <= 0.0) {
    var early_output : FragmentOutput;
    early_output.color = object_color;
    return early_output;
  }

  let shadow_intensity = shaderParams.shadow_opacity * shadow_sample.a;
  let combined_color = vec4<f32>(shaderParams.shadow_color * shadow_intensity, shadow_intensity);
  let final_color = object_color + combined_color * (1.0 - object_color.a);

  var output_result : FragmentOutput;
  output_result.color = final_color;
  return output_result;
}