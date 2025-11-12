%%FRAGMENTINPUT_STRUCT%%

%%FRAGMENTOUTPUT_STRUCT%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
    rim_color : vec3<f32>,
    opacity : f32,
    blending : f32,
    threshold : f32,
    angle : f32,
    cone : f32,
    amount : f32,
    sharpness : f32
};

%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

%%C3PARAMS_STRUCT%%

%%C3_UTILITY_FUNCTIONS%%

@fragment
fn main(input : FragmentInput) -> FragmentOutput {
    let uv = input.fragUV;

    if (shaderParams.opacity == 0.0 || shaderParams.amount == 0.0 || shaderParams.threshold > 1.0) {
        let front = textureSample(textureFront, samplerFront, uv);
        var output : FragmentOutput;
        output.color = front;
        return output;
    }

    let front = textureSample(textureFront, samplerFront, uv);

    if (front.a == 0.0) {
        var output : FragmentOutput;
        output.color = front;
        return output;
    }

    let brightness = dot(front.rgb, vec3<f32>(0.299, 0.587, 0.114));
    let threshold_factor = 1.0 - smoothstep(shaderParams.threshold, shaderParams.threshold + 0.1, brightness);

    if (threshold_factor <= 0.0) {
        var output : FragmentOutput;
        output.color = front;
        return output;
    }

    let object_center = (c3Params.srcOriginStart + c3Params.srcOriginEnd) * 0.5;
    let to_pixel = uv - object_center;

    let light_direction = vec2<f32>(cos(radians(shaderParams.angle)), sin(radians(shaderParams.angle)));
    let pixel_direction = normalize(to_pixel);
    let cos_angle = dot(light_direction, pixel_direction);
    let cone_cos = cos(radians(shaderParams.cone));

    let smooth_range = mix(0.5, 0.001, min(shaderParams.sharpness, 1.0));
    let cone_edge0 = mix(cone_cos - smooth_range, cone_cos, min(shaderParams.sharpness, 1.0));
    let cone_edge1 = mix(cone_cos + smooth_range, cone_cos, min(shaderParams.sharpness, 1.0));
    let cone_factor = smoothstep(cone_edge0, cone_edge1, cos_angle);

    let distance_from_center = length(to_pixel);
    let max_distance = 0.5;
    let normalized_distance = distance_from_center / max_distance;

    let amount_smooth_range = mix(0.5, 0.001, min(shaderParams.sharpness, 1.0));
    let amount_edge0 = mix(0.0, shaderParams.amount * 0.01, min(shaderParams.sharpness, 1.0));
    let amount_edge1 = mix(shaderParams.amount * 0.01, shaderParams.amount * 0.01, min(shaderParams.sharpness, 1.0));
    let amount_factor = 1.0 - smoothstep(amount_edge0 - amount_smooth_range, amount_edge1 + amount_smooth_range, 1.0 - normalized_distance);

    let inline_alpha = front.a * shaderParams.opacity * cone_factor * amount_factor * threshold_factor;

    let normal_blend = mix(front.rgb, shaderParams.rim_color, inline_alpha);
    let additive_blend = front.rgb + shaderParams.rim_color * inline_alpha;
    let result_rgb = mix(normal_blend, additive_blend, shaderParams.blending);

    var output : FragmentOutput;
    output.color = vec4<f32>(result_rgb, front.a);
    return output;
}