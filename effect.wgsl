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

    let object_center = (c3Params.srcOriginStart + c3Params.srcOriginEnd) * 0.5;
    let to_pixel = uv - object_center;

    let light_direction = vec2<f32>(cos(radians(shaderParams.angle)), sin(radians(shaderParams.angle)));
    let pixel_direction = normalize(to_pixel);
    let cos_angle = dot(light_direction, pixel_direction);
    let cone_cos = cos(radians(shaderParams.cone));
    let cone_factor = smoothstep(cone_cos, 1.0, cos_angle);

    let inline_alpha = front.a * shaderParams.opacity * cone_factor;

    let normal_blend = mix(front.rgb, shaderParams.rim_color, inline_alpha);
    let additive_blend = front.rgb + shaderParams.rim_color * inline_alpha;
    let result_rgb = mix(normal_blend, additive_blend, shaderParams.blending);

    var output : FragmentOutput;
    output.color = vec4<f32>(result_rgb, front.a);
    return output;
}