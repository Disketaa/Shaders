%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
  intensity : f32,
  brightness : f32,
  falloff : f32,
  threshold : f32,
  samples : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

const ANGLE_MAT : mat2x2<f32> = mat2x2<f32>(-0.7373688, 0.6754904, -0.6754904, -0.7373688);
const WEIGHTS : vec3<f32> = vec3<f32>(0.2126, 0.7152, 0.0722);

fn luminance(rgb : vec3<f32>) -> f32 {
  return dot(rgb, WEIGHTS);
}

fn safeTextureSample(tex : texture_2d<f32>, samp : sampler, coord : vec2<f32>) -> vec4<f32> {
  let clampedCoord = clamp(coord, vec2<f32>(0.001), vec2<f32>(0.999));
  return textureSampleLevel(tex, samp, clampedCoord, 0.0);
}

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
  let uv = input.fragUV;
  let textureSize = vec2<f32>(textureDimensions(textureFront));
  let texelSize = 1.0 / textureSize;

  var blur : vec4<f32> = vec4<f32>(0.0);
  var totalWeight : f32 = 0.0;

  let radius = shaderParams.intensity * 10.0;
  let scale = radius * inverseSqrt(shaderParams.samples);

  var point : vec2<f32> = vec2<f32>(scale, 0.0);
  var rad : f32 = 1.0;

  for (var i : i32 = 0; i < i32(shaderParams.samples); i++) {
    point = ANGLE_MAT * point;
    rad = rad + 1.0 / rad;

    let coord = uv + point * (rad - 1.0) * texelSize;
    let sampleColor = safeTextureSample(textureFront, samplerFront, coord);

    let lum = luminance(sampleColor.rgb);
    let thresholdLow = shaderParams.threshold;
    let thresholdHigh = shaderParams.threshold + shaderParams.falloff;  // Use falloff
    let bloomFactor = smoothstep(thresholdLow, thresholdHigh, lum);

    let bloomSample = vec4<f32>(sampleColor.rgb * bloomFactor, bloomFactor) * shaderParams.brightness;
    let weight = 1.0 / rad;

    blur = blur + bloomSample * weight;
    totalWeight = totalWeight + weight;
  }

  blur = blur / totalWeight;
  let originalColor = textureSample(textureFront, samplerFront, uv);

  var output : FragmentOutput;
  output.color = originalColor + blur;
  return output;
}