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
        var output : FragmentOutput;
        output.color = textureSample(textureFront, samplerFront, uv);
        return output;
    }

    let front = textureSample(textureFront, samplerFront, uv);

    let object_center = (c3Params.srcOriginStart + c3Params.srcOriginEnd) * 0.5;
    let to_pixel = uv - object_center;

    let pixel_angle = atan2(to_pixel.y, to_pixel.x);
    let center_angle = radians(shaderParams.angle);
    let angle_diff = abs(pixel_angle - center_angle);
    let normalized_diff = min(angle_diff, radians(360.0) - angle_diff);

    let half_cone = radians(shaderParams.cone) * 0.5;
    let rim_strength = 1.0 - smoothstep(0.0, half_cone, normalized_diff);

    let layoutSize = abs(c3Params.layoutEnd - c3Params.layoutStart);
    let texelSize = abs(c3Params.srcOriginEnd - c3Params.srcOriginStart) / layoutSize;
    let distance_from_center = length(to_pixel / texelSize);
    let rim_threshold = shaderParams.amount * 0.5;
    let rim_falloff = 1.0;
    let distance_factor = 1.0 - smoothstep(rim_threshold - rim_falloff, rim_threshold + rim_falloff, distance_from_center);

    let rim_alpha = rim_strength * distance_factor * front.a * shaderParams.opacity;

    let normal_blend = mix(front.rgb, shaderParams.rim_color, rim_alpha);
    let additive_blend = front.rgb + shaderParams.rim_color * rim_alpha;
    let result_rgb = mix(normal_blend, additive_blend, shaderParams.blending);

    var output : FragmentOutput;
    output.color = vec4<f32>(result_rgb, front.a);
    return output;
}