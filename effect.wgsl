%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
    rim_color : vec3<f32>,
    opacity : f32,
    angle : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
    let uv = input.fragUV;
    let textureSize = vec2<f32>(textureDimensions(textureFront));
    let pixelSize = 1.0 / textureSize;

    let front = textureSample(textureFront, samplerFront, uv);

    let angle_rad = radians(shaderParams.angle);

    let offset = vec2<f32>(cos(angle_rad), sin(angle_rad)) * pixelSize * 2.0;

    let offset_coord = clamp(uv + offset, vec2<f32>(0.001), vec2<f32>(0.999));
    let offset_sample = textureSample(textureFront, samplerFront, offset_coord);

    let inline_alpha = front.a * (1.0 - offset_sample.a) * shaderParams.opacity;

    let result_rgb = mix(front.rgb, shaderParams.rim_color, inline_alpha);

    var output : FragmentOutput;
    output.color = vec4<f32>(result_rgb, front.a);
    return output;
}