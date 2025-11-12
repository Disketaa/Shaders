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
        mediump vec4 front = texture2D(samplerFront, vTex);
        gl_FragColor = front;
        return;
    }

    mediump vec4 front = texture2D(samplerFront, vTex);

    if (front.a == 0.0) {
        gl_FragColor = front;
        return;
    }

    mediump vec2 to_pixel = vTex - (srcOriginStart + srcOriginEnd) * 0.5;

    mediump vec2 light_direction = vec2(cos(radians(angle)), sin(radians(angle)));
    mediump vec2 pixel_direction = normalize(to_pixel);
    mediump float cos_angle = dot(light_direction, pixel_direction);
    mediump float cone_cos = cos(radians(cone));
    mediump float cone_factor = smoothstep(cone_cos, 1.0, cos_angle);

    mediump float inline_alpha = front.a * opacity * cone_factor;

    mediump vec3 normal_blend = mix(front.rgb, rim_color, inline_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * inline_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}