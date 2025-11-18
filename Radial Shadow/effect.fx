varying mediump vec2 vTex;
uniform lowp vec3 shadow_color;
uniform lowp float shadow_opacity;
uniform mediump float sharpness;
uniform lowp float horizontal_center;
uniform lowp float vertical_center;
uniform lowp float horizontal_scale;
uniform lowp float vertical_scale;
uniform mediump float horizontal_offset;
uniform mediump float vertical_offset;
uniform sampler2D samplerFront;

void main(void) {
  lowp vec4 object_color = texture2D(samplerFront, vTex);

  if (shadow_opacity <= 0.0) {
    gl_FragColor = object_color;
    return;
  }

  mediump vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / abs(layoutEnd - layoutStart);
  mediump vec2 pixelSize = vec2(texelSize.x, -texelSize.y);
  mediump vec2 object_size = srcOriginEnd - srcOriginStart;
  mediump vec2 center = srcOriginStart + object_size * vec2(horizontal_center, vertical_center);

  mediump vec2 offset_uv = vTex;
  mediump vec2 offset_vec = vec2(-horizontal_offset * pixelSize.x, vertical_offset * pixelSize.y);

  if (horizontal_offset != 0.0 || vertical_offset != 0.0) {
    offset_uv += offset_vec;
  }

  mediump vec2 scale_vec = vec2(horizontal_scale, vertical_scale);
  mediump vec2 base_coord = center + (offset_uv - center) / scale_vec;

  mediump vec2 src_half_size = object_size * 0.5;
  mediump vec2 dist_vec = abs(base_coord - center);
  mediump float dist = length(dist_vec / src_half_size);

  mediump float smooth_range = mix(0.5, 0.001, min(sharpness, 1.0));
  mediump float circle_alpha = 1.0 - smoothstep(1.0 - smooth_range, 1.0 + smooth_range, dist);

  if (sharpness > 0.0) {
    mediump float clamped_sharpness = min(sharpness, 1.0);
    mediump float sharpness_cutoff = 0.5 + clamped_sharpness * 0.5;
    circle_alpha = mix(circle_alpha, step(sharpness_cutoff, circle_alpha), clamped_sharpness);
  }

  if (circle_alpha <= 0.0) {
    gl_FragColor = object_color;
    return;
  }

  lowp float shadow_intensity = shadow_opacity * circle_alpha;
  lowp vec3 shadow_rgb = shadow_color * shadow_intensity;
  mediump vec4 final_color = object_color + vec4(shadow_rgb, shadow_intensity) * (1.0 - object_color.a);

  gl_FragColor = final_color;
}