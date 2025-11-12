uniform lowp vec3 rim_color;
uniform mediump float opacity;
uniform mediump float blending;
uniform mediump float threshold;
uniform mediump float angle;
uniform mediump float cone;
uniform mediump float amount;
uniform mediump float sharpness;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 pixelSize;

void main(void)
{
    if (opacity == 0.0 || amount == 0.0 || threshold > 1.0) {
        mediump vec4 front = texture2D(samplerFront, vTex);
        gl_FragColor = front;
        return;
    }

    mediump vec4 front = texture2D(samplerFront, vTex);

    if (front.a == 0.0) {
        gl_FragColor = front;
        return;
    }

    mediump float brightness = dot(front.rgb, vec3(0.299, 0.587, 0.114));
    mediump float threshold_factor = 1.0 - smoothstep(threshold, threshold + 0.1, brightness);

    if (threshold_factor <= 0.0) {
        gl_FragColor = front;
        return;
    }

    mediump vec2 to_pixel = vTex - (srcOriginStart + srcOriginEnd) * 0.5;

    mediump vec2 light_direction = vec2(cos(radians(angle)), sin(radians(angle)));
    mediump vec2 pixel_direction = normalize(to_pixel);
    mediump float cos_angle = dot(light_direction, pixel_direction);
    mediump float cone_cos = cos(radians(cone));

    mediump float smooth_range = mix(0.5, 0.001, min(sharpness, 1.0));
    mediump float cone_edge0 = mix(cone_cos - smooth_range, cone_cos, min(sharpness, 1.0));
    mediump float cone_edge1 = mix(cone_cos + smooth_range, cone_cos, min(sharpness, 1.0));
    mediump float cone_factor = smoothstep(cone_edge0, cone_edge1, cos_angle);

    mediump float distance_from_center = length(to_pixel);
    mediump float max_distance = 0.5;
    mediump float normalized_distance = distance_from_center / max_distance;

    mediump float amount_smooth_range = mix(0.5, 0.001, min(sharpness, 1.0));
    mediump float amount_edge0 = mix(0.0, amount * 0.01, min(sharpness, 1.0));
    mediump float amount_edge1 = mix(amount * 0.01, amount * 0.01, min(sharpness, 1.0));
    mediump float amount_factor = 1.0 - smoothstep(amount_edge0 - amount_smooth_range, amount_edge1 + amount_smooth_range, 1.0 - normalized_distance);

    mediump float inline_alpha = front.a * opacity * cone_factor * amount_factor * threshold_factor;

    mediump vec3 normal_blend = mix(front.rgb, rim_color, inline_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * inline_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}