uniform lowp vec3 rim_color;
uniform mediump float opacity;
uniform mediump float blending;
uniform mediump float angle;
uniform mediump float cone;
uniform mediump float amount;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 pixelSize;

void main(void)
{
    if (opacity == 0.0) {
        gl_FragColor = texture2D(samplerFront, vTex);
        return;
    }

    mediump vec4 front = texture2D(samplerFront, vTex);

    mediump vec2 object_center = (srcOriginStart + srcOriginEnd) * 0.5;
    mediump vec2 to_pixel = vTex - object_center;

    mediump float pixel_angle = atan2(to_pixel.y, to_pixel.x);
    mediump float center_angle = radians(angle);
    mediump float angle_diff = abs(pixel_angle - center_angle);
    mediump float normalized_diff = min(angle_diff, radians(360.0) - angle_diff);

    mediump float half_cone = radians(cone) * 0.5;
    mediump float rim_strength = 1.0 - smoothstep(0.0, half_cone, normalized_diff);

    mediump vec2 layoutSize = abs(vec2(layoutEnd.x - layoutStart.x, layoutEnd.y - layoutStart.y));
    mediump vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / layoutSize;
    mediump float distance_from_center = length(to_pixel / texelSize);
    mediump float rim_threshold = amount * 0.5;
    mediump float rim_falloff = 1.0;
    mediump float distance_factor = 1.0 - smoothstep(rim_threshold - rim_falloff, rim_threshold + rim_falloff, distance_from_center);

    mediump float rim_alpha = rim_strength * distance_factor * front.a * opacity;

    mediump vec3 normal_blend = mix(front.rgb, rim_color, rim_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * rim_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}