uniform lowp vec3 rim_color;
uniform mediump float opacity;
uniform mediump float angle;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 pixelSize;

void main(void)
{
    mediump vec4 front = texture2D(samplerFront, vTex);
    mediump float angle_rad = radians(angle);

    mediump vec2 offset = vec2(cos(angle_rad), sin(angle_rad)) * pixelSize * 2.0;
    mediump vec4 offset_sample = texture2D(samplerFront, vTex + offset);

    mediump float inline_alpha = front.a * (1.0 - offset_sample.a) * opacity;

    mediump vec3 result_rgb = mix(front.rgb, rim_color, inline_alpha);
    mediump float result_alpha = front.a;

    gl_FragColor = vec4(result_rgb, result_alpha);
}