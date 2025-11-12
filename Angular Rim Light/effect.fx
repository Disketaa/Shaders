#ifdef GL_FRAGMENT_PRECISION_HIGH
#define highmedp highp
#else
#define highmedp mediump
#endif

precision lowp float;

varying mediump vec2 vTex;
uniform lowp sampler2D samplerFront;
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
uniform lowp sampler2D samplerBack;
uniform lowp sampler2D samplerDepth;
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
uniform highmedp float seconds;
uniform mediump vec2 pixelSize;
uniform mediump float layerScale;
uniform mediump float layerAngle;
uniform mediump float devicePixelRatio;
uniform mediump float zNear;
uniform mediump float zFar;

uniform lowp vec3 rim_color;
uniform mediump float opacity;
uniform mediump float blending;
uniform mediump float threshold;
uniform mediump float angle;
uniform mediump float cone;
uniform mediump float amount;
uniform mediump float sharpness;

void main(void) {
    mediump vec4 front = texture2D(samplerFront, vTex);

    if (opacity == 0.0 || amount == 0.0 || front.a == 0.0) {
        gl_FragColor = front;
        return;
    }

    mediump float brightness = dot(front.rgb, vec3(0.299, 0.587, 0.114));

    mediump float angle_rad = radians(angle);
    mediump float cone_rad = radians(cone);
    mediump float clamped_sharpness = min(sharpness, 1.0);

    mediump vec2 srcSize = srcOriginEnd - srcOriginStart;
    mediump vec2 object_center = srcOriginStart + (srcSize * 0.5);
    mediump vec2 to_pixel = vTex - object_center;

    mediump vec2 light_dir = vec2(cos(angle_rad), sin(angle_rad));
    mediump vec2 pixel_dir = normalize(to_pixel);
    mediump float cos_angle = dot(light_dir, pixel_dir);
    mediump float cone_cos = cos(cone_rad);

    mediump float smooth_range = mix(0.1, 0.001, clamped_sharpness);
    mediump float cone_factor = smoothstep(cone_cos - smooth_range, cone_cos + smooth_range, cos_angle);

    mediump float srcRadius = length(srcSize) * 0.5;
    mediump float normalized_dist = length(to_pixel) / srcRadius;
    mediump float amount_norm = amount * 0.01;
    mediump float amount_factor = 1.0 - smoothstep(amount_norm - smooth_range, amount_norm + smooth_range, 1.0 - normalized_dist);

    mediump float threshold_factor = 1.0 - smoothstep(threshold - 0.01, threshold + 0.01, brightness);

    mediump float rim_alpha = opacity * cone_factor * amount_factor * threshold_factor * front.a;
    mediump vec3 normal_blend = mix(front.rgb, rim_color, rim_alpha);
    mediump vec3 additive_blend = front.rgb + rim_color * rim_alpha;
    mediump vec3 result_rgb = mix(normal_blend, additive_blend, blending);

    gl_FragColor = vec4(result_rgb, front.a);
}