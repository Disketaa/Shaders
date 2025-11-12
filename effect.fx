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

    mediump vec2 layoutSize = abs(vec2(layoutEnd.x - layoutStart.x, (layoutEnd.y - layoutStart.y)));
    mediump vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / layoutSize;
    mediump vec2 pixelSize = vec2(texelSize.x, -texelSize.y);

    mediump float angle_rad = radians(angle);

    mediump vec2 direction_to_light = vec2(cos(angle_rad), sin(angle_rad));
    mediump vec2 to_pixel = vTex - (srcOriginStart + srcOriginEnd) * 0.5;
    mediump vec2 pixel_direction = normalize(to_pixel);

    mediump float cos_angle = dot(direction_to_light, pixel_direction);
    mediump float cone_cos = cos(radians(cone));
    mediump float cone_factor = 1.0 - smoothstep(cone_cos, 1.0, cos_angle);

    mediump vec2 offset = direction_to_light * pixelSize * amount;
    mediump vec2 offset_coord = clamp(vTex + offset, vec2(0.001), vec2(0.999));
    mediump vec4 offset_sample = texture2D(samplerFront, offset_coord);

    mediump float inline_alpha = front.a * (1.0 - offset_sample.a) * opacity * cone_factor;

    mediump vec3 normal_blend = mix(front.rgb, rim_color, inline_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * inline_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}