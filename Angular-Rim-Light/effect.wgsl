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
    let front = textureSample(textureFront, samplerFront, uv);
    var output : FragmentOutput;

    if (shaderParams.opacity == 0.0 || shaderParams.amount == 0.0 || front.a == 0.0) {
        output.color = front;
        return output;
    }

    let brightness = dot(front.rgb, vec3<f32>(0.299, 0.587, 0.114));
    if (brightness <= shaderParams.threshold) {
        output.color = front;
        return output;
    }

    let angle_rad = radians(shaderParams.angle);
    let cone_rad = radians(shaderParams.cone);
    let clamped_sharpness = min(shaderParams.sharpness, 1.0);

    let object_center = (c3Params.srcOriginStart + c3Params.srcOriginEnd) * 0.5;
    let to_pixel = uv - object_center;
    let light_dir = vec2<f32>(cos(angle_rad), sin(angle_rad));
    let pixel_dir = normalize(to_pixel);
    let cos_angle = dot(light_dir, pixel_dir);
    let cone_cos = cos(cone_rad);

    let smooth_range = mix(0.1, 0.001, clamped_sharpness);
    let cone_factor = smoothstep(cone_cos - smooth_range, cone_cos + smooth_range, cos_angle);

    let normalized_dist = length(to_pixel) * 2.0;
    let amount_norm = shaderParams.amount * 0.01;
    let amount_factor = 1.0 - smoothstep(amount_norm - smooth_range, amount_norm + smooth_range, 1.0 - normalized_dist);

    let threshold_factor = step(shaderParams.threshold, brightness);
    let rim_alpha = shaderParams.opacity * cone_factor * amount_factor * threshold_factor * front.a;
    let normal_blend = mix(front.rgb, shaderParams.rim_color, rim_alpha);
    let additive_blend = front.rgb + shaderParams.rim_color * rim_alpha;
    let result_rgb = mix(normal_blend, additive_blend, shaderParams.blending);
    output.color = vec4<f32>(result_rgb, front.a);

    return output;
}