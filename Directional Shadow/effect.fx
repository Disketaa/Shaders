varying mediump vec2 vTex;
uniform lowp vec3 shadow_color;
uniform lowp float shadow_opacity;
uniform mediump float sharpness;
uniform mediump float angle;
uniform lowp float horizontal_center;
uniform lowp float vertical_center;
uniform lowp float horizontal_scale;
uniform lowp float vertical_scale;
uniform mediump float horizontal_offset;
uniform mediump float vertical_offset;
uniform sampler2D samplerFront;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;

void main() {
  if (shadow_opacity <= 0.0) {
    gl_FragColor = texture2D(samplerFront, vTex);
    return;
  }

  mediump vec2 layoutSize = abs(layoutEnd - layoutStart);
  mediump vec2 texelSize = abs(srcOriginEnd - srcOriginStart) / layoutSize;
  mediump vec2 pixelSize = vec2(texelSize.x, -texelSize.y);

  lowp vec4 object_color = texture2D(samplerFront, vTex);
  lowp vec4 shadow_sample = vec4(0.0);

  mediump vec2 object_size = srcOriginEnd - srcOriginStart;
  mediump vec2 object_coord = (vTex - srcOriginStart) / object_size;
  

  mediump vec2 offset_coord = object_coord;
  if (horizontal_offset != 0.0 || vertical_offset != 0.0) {
    offset_coord += vec2(-horizontal_offset * texelSize.x, -vertical_offset * texelSize.y);
  }

  mediump vec2 scaled_coord = offset_coord;
  if (horizontal_scale != 1.0 || vertical_scale != 1.0) {
    mediump vec2 scale_center = vec2(horizontal_center, vertical_center);
    scaled_coord = scale_center + (scaled_coord - scale_center) / vec2(horizontal_scale, vertical_scale);
  }

  mediump vec2 rotated_coord = scaled_coord;
  if (angle != 0.0) {
    mediump float rad = radians(angle);
    mediump float cosA = cos(rad);
    mediump float sinA = sin(rad);
    mediump vec2 center_offset = rotated_coord - vec2(horizontal_center, vertical_center);
    rotated_coord = vec2(horizontal_center, vertical_center) + vec2(
      cosA * center_offset.x - sinA * center_offset.y,
      sinA * center_offset.x + cosA * center_offset.y
    );
  }

  mediump vec2 shadow_coord = srcOriginStart + rotated_coord * object_size;

  if (rotated_coord.x >= 0.0 && rotated_coord.x <= 1.0 && 
      rotated_coord.y >= 0.0 && rotated_coord.y <= 1.0) {
    shadow_sample = texture2D(samplerFront, shadow_coord);
  }

  if (sharpness > 0.0) {
    mediump float sharpness_cutoff = 0.5 + min(sharpness, 1.0) * 0.5;
    shadow_sample.a = mix(shadow_sample.a, step(sharpness_cutoff, shadow_sample.a), min(sharpness, 1.0));
  }

  if (shadow_sample.a <= 0.0) {
    gl_FragColor = object_color;
    return;
  }

  lowp float shadow_intensity = shadow_opacity * shadow_sample.a;
  mediump vec4 combined_color = vec4(shadow_color * shadow_intensity, shadow_intensity);
  mediump vec4 final_color = object_color + combined_color * (1.0 - object_color.a);

  gl_FragColor = final_color;
}