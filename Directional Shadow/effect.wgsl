%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
  shadow_color : vec3<f32>,
  shadow_opacity : f32,
  sharpness : f32,
  angle : f32,
  horizontal_center : f32,
  vertical_center : f32,
  horizontal_scale : f32,
  vertical_scale : f32,
  horizontal_offset : f32,
  vertical_offset : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
  var output : FragmentOutput;

  if (shaderParams.shadow_opacity <= 0.0) {
    output.color = textureSample(textureFront, samplerFront, input.fragUV);
    return output;
  }

  let layoutSize : vec2<f32> = abs(c3Params.layoutEnd - c3Params.layoutStart);
  let texelSize : vec2<f32> = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;
  let pixelSize : vec2<f32> = vec2<f32>(texelSize.x, -texelSize.y);

  let object_color : vec4<f32> = textureSample(textureFront, samplerFront, input.fragUV);
  var shadow_sample : vec4<f32> = vec4<f32>(0.0);

  let object_size : vec2<f32> = c3Params.srcOriginEnd - c3Params.srcOriginStart;
  let object_coord : vec2<f32> = (input.fragUV - c3Params.srcOriginStart) / object_size;

  var offset_coord : vec2<f32> = object_coord;
  if (shaderParams.horizontal_offset != 0.0 || shaderParams.vertical_offset != 0.0) {
    offset_coord = offset_coord + vec2<f32>(-shaderParams.horizontal_offset, shaderParams.vertical_offset) * pixelSize / object_size;
  }

  var scaled_coord : vec2<f32> = offset_coord;
  if (shaderParams.horizontal_scale != 1.0 || shaderParams.vertical_scale != 1.0) {
    let scale_center : vec2<f32> = vec2<f32>(shaderParams.horizontal_center, shaderParams.vertical_center);
    scaled_coord = scale_center + (scaled_coord - scale_center) / vec2<f32>(shaderParams.horizontal_scale, shaderParams.vertical_scale);
  }

  var rotated_coord : vec2<f32> = scaled_coord;
  if (shaderParams.angle != 0.0) {
    let rad : f32 = shaderParams.angle * (3.141592653589793 / 180.0);
    let cosA : f32 = cos(rad);
    let sinA : f32 = sin(rad);
    let center_offset : vec2<f32> = rotated_coord - vec2<f32>(shaderParams.horizontal_center, shaderParams.vertical_center);
    rotated_coord = vec2<f32>(shaderParams.horizontal_center, shaderParams.vertical_center) + vec2<f32>(
      cosA * center_offset.x - sinA * center_offset.y,
      sinA * center_offset.x + cosA * center_offset.y
    );
  }

  let shadow_coord : vec2<f32> = c3Params.srcOriginStart + rotated_coord * object_size;

  let inBounds : bool = rotated_coord.x >= 0.0 && rotated_coord.x <= 1.0 && rotated_coord.y >= 0.0 && rotated_coord.y <= 1.0;

  shadow_sample = textureSample(textureFront, samplerFront, shadow_coord);

  if (!inBounds) {
    shadow_sample = vec4<f32>(0.0);
  }

  if (shaderParams.sharpness > 0.0) {
    let sharpness_cutoff : f32 = 0.5 + min(shaderParams.sharpness, 1.0) * 0.5;
    let sharpAlpha : f32 = mix(shadow_sample.a, select(0.0, 1.0, shadow_sample.a >= sharpness_cutoff), min(shaderParams.sharpness, 1.0));
    shadow_sample.a = sharpAlpha;
  }

  if (shadow_sample.a <= 0.0) {
    output.color = object_color;
    return output;
  }

  let shadow_intensity : f32 = shaderParams.shadow_opacity * shadow_sample.a;
  let combined_color : vec4<f32> = vec4<f32>(shaderParams.shadow_color * shadow_intensity, shadow_intensity);
  let final_color : vec4<f32> = object_color + combined_color * (1.0 - object_color.a);

  output.color = final_color;
  return output;
}