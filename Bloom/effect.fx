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

uniform mediump float intensity;
uniform mediump float brightness;
uniform mediump float falloff;
uniform mediump float threshold;
uniform mediump float samples;

const highp mat2 ANGLE_MAT = mat2(-0.7373688, 0.6754904, -0.6754904, -0.7373688);
const mediump vec3 WEIGHTS = vec3(0.2126, 0.7152, 0.0722);

mediump float luminance(mediump vec3 rgb) {
  return dot(rgb, WEIGHTS);
}

mediump vec4 safeTextureSample(mediump vec2 coord) {
  mediump vec2 clampedCoord = clamp(coord, vec2(0.001), vec2(0.999));
  return texture2D(samplerFront, clampedCoord);
}

void main(void) {
  mediump vec2 texelSize = pixelSize;

  mediump vec4 blur = vec4(0.0);
  mediump float totalWeight = 0.0;

  mediump float radius = intensity * 10.0;
  mediump float scale = radius * inversesqrt(samples);

  highp vec2 point = vec2(scale, 0.0);
  mediump float rad = 1.0;

  const int MAX_SAMPLES = 64;
  int sampleCount = int(clamp(samples, 1.0, float(MAX_SAMPLES)));

  for (int i = 0; i < MAX_SAMPLES; i++) {
    if (i >= sampleCount) break;

    point = ANGLE_MAT * point;
    rad += 1.0 / rad;

    mediump vec2 coord = vTex + point * (rad - 1.0) * texelSize;
    mediump vec4 sampleColor = safeTextureSample(coord);

    mediump float lum = luminance(sampleColor.rgb);
    mediump float thresholdLow = threshold;
    mediump float thresholdHigh = threshold + falloff;
    mediump float bloomFactor = smoothstep(thresholdLow, thresholdHigh, lum);

    mediump vec4 bloomSample = vec4(sampleColor.rgb * bloomFactor, bloomFactor) * brightness;
    mediump float weight = 1.0 / rad;

    blur += bloomSample * weight;
    totalWeight += weight;
    }

  blur /= totalWeight;
  mediump vec4 originalColor = texture2D(samplerFront, vTex);

  gl_FragColor = originalColor + blur;
}