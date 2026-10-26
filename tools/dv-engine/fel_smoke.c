// Synthetic composer integration vectors, not a Dolby reference certification.
// Equal-channel fields make the test independent of the creative color matrix.
// Compare BL+EL composition with an independently precomposed BL through the
// same color pipeline, then require a visible difference from unmodified BL.
#include <math.h>
#include <stdio.h>

#include <libplacebo/log.h>
#include <libplacebo/opengl.h>
#include <libplacebo/renderer.h>

enum { SIDE = 32, VALUES = SIDE * SIDE * 4 };

static pl_tex field(pl_gpu gpu, pl_fmt fmt, int side, float value) {
  float pixels[VALUES];
  for (int i = 0; i < side * side; ++i) {
    for (int c = 0; c < 3; ++c) pixels[i * 4 + c] = value;
    pixels[i * 4 + 3] = 1.0f;
  }
  return pl_tex_create(gpu, pl_tex_params(
      .w = side, .h = side, .format = fmt, .sampleable = true, .initial_data = pixels));
}

static struct pl_frame frame(pl_tex texture) {
  return (struct pl_frame){
      .num_planes = 1,
      .planes = {{.texture = texture, .components = 4, .component_mapping = {0, 1, 2, 3}}},
      .repr = {.sys = PL_COLOR_SYSTEM_RGB, .levels = PL_COLOR_LEVELS_FULL},
      .color = pl_color_space_hdr10};
}

static int render(pl_renderer renderer, pl_gpu gpu, const struct pl_frame* input,
                  struct pl_frame* output, float* pixels) {
  if (!pl_render_image(renderer, input, output, &pl_render_default_params) ||
      pl_renderer_get_errors(renderer).errors != PL_RENDER_ERR_NONE) return 0;
  return pl_tex_download(gpu, pl_tex_transfer_params(.tex = output->planes[0].texture, .ptr = pixels));
}

int test_fel_residual(void) {
  int result = 1;
  pl_log log = pl_log_create(PL_API_VER, pl_log_params(.log_cb = pl_log_simple, .log_level = PL_LOG_WARN));
  pl_opengl gl = pl_opengl_create(log, pl_opengl_params(.allow_software = true));
  if (!gl) {
    pl_log_destroy(&log);
    return 1;
  }
  pl_gpu gpu = gl->gpu;
  pl_renderer renderer = pl_renderer_create(log, gpu);
  pl_fmt fmt = pl_find_named_fmt(gpu, "rgba32f");
  pl_tex base = NULL, el = NULL, expected = NULL, target = NULL;
  if (!renderer || !fmt) goto cleanup;
  base = field(gpu, fmt, SIDE, 0.4f * 1024.0f / 1023.0f);
  target = pl_tex_create(gpu, pl_tex_params(
      .w = SIDE, .h = SIDE, .format = fmt, .renderable = true, .host_readable = true));
  if (!base || !target) goto cleanup;

  struct pl_dovi_metadata metadata = {0};
  metadata.nonlinear = (pl_matrix3x3){{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}};
  metadata.linear = metadata.nonlinear;
  for (int c = 0; c < 3; ++c) {
    metadata.comp[c].num_pivots = 2;
    metadata.comp[c].pivots[1] = 1.0f;
    metadata.comp[c].poly_coeffs[0][1] = 1.0f;
  }
  struct pl_frame input = frame(base), output = frame(target);
  input.repr.sys = PL_COLOR_SYSTEM_DOLBYVISION;
  input.repr.bits = (struct pl_bit_encoding){.sample_depth = 10, .color_depth = 10};
  input.repr.dovi = &metadata;
  float baseline[VALUES], actual[VALUES], reference[VALUES];
  if (!render(renderer, gpu, &input, &output, baseline)) goto cleanup;

  // A declared FEL stream with a missing EL must fail the render and retain
  // libplacebo's sampling error. It must not silently report a successful BL.
  struct pl_frame missing = frame(NULL);
  input.enhancement_layer = &missing;
  metadata.nlq_active = true;
  const bool missing_el_rendered = pl_render_image(renderer, &input, &output, &pl_render_default_params);
  if (missing_el_rendered || !(pl_renderer_get_errors(renderer).errors & PL_RENDER_ERR_SAMPLING)) {
    fputs("Missing FEL layer was not rejected\n", stderr);
    goto cleanup;
  }
  puts("Missing FEL layer was rejected");
  pl_renderer_reset_errors(renderer, NULL);
  input.enhancement_layer = NULL;
  metadata.nlq_active = false;

  // LINEAR_DZ vectors: zero, both signs, threshold, both clamp directions.
  // Expected residuals are explicit values, not computed by a copy of GLSL.
  const struct {
    float code, slope, threshold, limit, residual;
  } cases[] = {
      {512, 0.1f, 0.05f, 1.0f, 0.0f},
      {513, 0.1f, 0.05f, 1.0f, 0.1f},
      {511, 0.1f, 0.05f, 1.0f, -0.1f},
      {515, 0.1f, 0.02f, 1.0f, 0.27f},
      {520, 0.1f, 0.05f, 0.15f, 0.15f},
      {504, 0.1f, 0.05f, 0.15f, -0.15f}};
  for (unsigned n = 0; n < sizeof(cases) / sizeof(cases[0]); ++n) {
    // Half-resolution EL exercises the layer upsampling path as well.
    el = field(gpu, fmt, SIDE / 2, cases[n].code / 1023.0f);
    expected = field(gpu, fmt, SIDE, (0.4f + cases[n].residual) * 1024.0f / 1023.0f);
    if (!el || !expected) goto cleanup;
    struct pl_frame enhancement = frame(el);
    enhancement.repr.bits = input.repr.bits;
    input.enhancement_layer = &enhancement;
    metadata.nlq_active = true;
    for (int c = 0; c < 3; ++c) {
      metadata.nlq[c].offset = 512;
      metadata.nlq[c].deadzone_slope = cases[n].slope;
      metadata.nlq[c].deadzone_threshold = cases[n].threshold;
      metadata.nlq[c].hdr_in_max = cases[n].limit;
    }
    if (!render(renderer, gpu, &input, &output, actual)) goto cleanup;
    struct pl_frame precomposed = input;
    precomposed.planes[0].texture = expected;
    precomposed.enhancement_layer = NULL;
    metadata.nlq_active = false;
    if (!render(renderer, gpu, &precomposed, &output, reference)) goto cleanup;

    float worst = 0.0f, changed = 0.0f;
    for (int i = 0; i < VALUES; ++i) {
      if (!isfinite(actual[i]) || !isfinite(reference[i])) goto cleanup;
      worst = fmaxf(worst, fabsf(actual[i] - reference[i]));
      changed = fmaxf(changed, fabsf(actual[i] - baseline[i]));
    }
    if (worst > 0.003f || (cases[n].residual != 0.0f && changed < 0.01f)) {
      fprintf(stderr, "FEL vector %u failed: reference error=%g, BL difference=%g\n", n, worst, changed);
      goto cleanup;
    }
    printf("FEL vector %u passed: reference error=%g, BL difference=%g\n", n, worst, changed);
    pl_tex_destroy(gpu, &el);
    pl_tex_destroy(gpu, &expected);
  }
  result = 0;

cleanup:
  pl_renderer_destroy(&renderer);
  pl_tex_destroy(gpu, &base);
  pl_tex_destroy(gpu, &el);
  pl_tex_destroy(gpu, &expected);
  pl_tex_destroy(gpu, &target);
  pl_opengl_destroy(&gl);
  pl_log_destroy(&log);
  if (result) fputs("Synthetic FEL composition check failed\n", stderr);
  return result;
}
