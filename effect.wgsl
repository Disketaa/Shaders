%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
    rim_color : vec3<f32>,
    opacity : f32,
    blending : f32,
    angle : f32,
    cone : f32,
    amount : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
    let uv = input.fragUV;

    if (shaderParams.opacity == 0.0) {
        let front = textureSample(textureFront, samplerFront, uv);
        var output : FragmentOutput;
        output.color = front;
        return output;
    }

    let front = textureSample(textureFront, samplerFront, uv);

    let layoutSize = abs(c3Params.layoutEnd - c3Params.layoutStart);
    let texelSize = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;
    let pixelSize = vec2<f32>(texelSize.x, -texelSize.y);
    let offset = vec2<f32>(cos(radians(shaderParams.angle)), sin(radians(shaderParams.angle))) * pixelSize * shaderParams.amount;

    let offset_coord = clamp(uv + offset, vec2<f32>(0.001), vec2<f32>(0.999));
    let offset_sample = textureSample(textureFront, samplerFront, offset_coord);

    let object_center = (c3Params.srcOriginStart + c3Params.srcOriginEnd) * 0.5;
    let to_pixel = uv - object_center;
    let pixel_angle = atan2(to_pixel.y, to_pixel.x);
    let angle_diff = abs(pixel_angle - radians(shaderParams.angle));
    let normalized_diff = min(angle_diff, radians(360.0) - angle_diff);
    let cone_factor = 1.0 - smoothstep(0.0, radians(shaderParams.cone), normalized_diff);

    let inline_alpha = front.a * (1.0 - offset_sample.a) * shaderParams.opacity * cone_factor;

    let normal_blend = mix(front.rgb, shaderParams.rim_color, inline_alpha);
    let additive_blend = front.rgb + shaderParams.rim_color * inline_alpha;
    let result_rgb = mix(normal_blend, additive_blend, shaderParams.blending);

    var output : FragmentOutput;
    output.color = vec4<f32>(result_rgb, front.a);
    return output;
}