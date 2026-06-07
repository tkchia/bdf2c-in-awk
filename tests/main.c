/* © 2025—2026 TK Chia
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0.  If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#undef NDEBUG
#include <assert.h>
#include <stddef.h>
#include <uchar.h>
#ifdef CHDR
# include CHDR
#else
# include "font.h"
#endif

#if ! defined font_default_direct && ! defined font_default_data
# error
#endif
#if FONT_DEFAULT_HEIGHT != 6 || FONT_DEFAULT_WIDTH_BYTES != 1
# error
#endif

typedef const uint8_t glyph_t[FONT_DEFAULT_HEIGHT][FONT_DEFAULT_WIDTH_BYTES];

static const glyph_t *
find_glyph (char32_t uc)
{
#if defined font_default_direct
  if (uc < FONT_DEFAULT_DIRECT_OFFSET
      || uc > FONT_DEFAULT_DIRECT_OFFSET + (FONT_DEFAULT_GLYPHS - 1))
    return NULL;

  return &font_default_direct[uc - FONT_DEFAULT_DIRECT_OFFSET];
#elif defined font_default_code_range_starts
  char32_t c0, c1, g0, lo = 0, hi = FONT_DEFAULT_CODE_RANGES, mi;

  while (lo != hi - 1)
    {
      mi = lo / 2 + hi / 2 + (lo & hi & 1);
      c0 = font_default_code_range_starts[mi].c0;
      if (uc < c0)
	hi = mi;
      else
	lo = mi;
    }

  c0 = font_default_code_range_starts[lo].c0;
  g0 = font_default_code_range_starts[lo].g0;
  if (lo != FONT_DEFAULT_CODE_RANGES - 1)
    c1 = c0 + font_default_code_range_starts[lo + 1].g0 - g0;
  else
    c1 = c0 + (FONT_DEFAULT_GLYPHS - g0);

  if (uc >= c0 && uc < c1)
    return &font_default_data[uc - c0 + g0];
  return NULL;
#else
  char32_t c0, lo = 0, hi = FONT_DEFAULT_GLYPHS, mi;

  while (lo != hi - 1)
    {
      mi = lo / 2 + hi / 2 + (lo & hi & 1);
# ifdef font_default_code_glyph_diffs
      c0 = mi + font_default_code_glyph_diffs[mi];
# else
      c0 = font_default_code_points[mi];
# endif
      if (uc < c0)
	hi = mi;
      else
	lo = mi;
    }

# ifdef font_default_code_glyph_diffs
  c0 = lo + font_default_code_glyph_diffs[lo];
# else
  c0 = font_default_code_points[lo];
# endif
  if (uc == c0)
    return &font_default_data[lo];
  return NULL;
#endif
}

int
main (void)
{
  const glyph_t *gly;

  gly = find_glyph (0x0000U);
  assert (!gly);
  gly = find_glyph (0x0001U);
  assert (!gly);
  gly = find_glyph (0x001eU);
  assert (!gly);
  gly = find_glyph (0x001fU);
  assert (!gly);

  gly = find_glyph (0x0020U);
  assert (gly);
  assert ((*gly)[0][0] == 0x00);
  assert ((*gly)[1][0] == 0x00);
  assert ((*gly)[2][0] == 0x00);
  assert ((*gly)[3][0] == 0x00);
  assert ((*gly)[4][0] == 0x00);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x0021U);
  assert (gly);
  assert ((*gly)[0][0] == 0x80);
  assert ((*gly)[1][0] == 0x80);
  assert ((*gly)[2][0] == 0x80);
  assert ((*gly)[3][0] == 0x00);
  assert ((*gly)[4][0] == 0x80);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x0040U);
  assert (gly);
  assert ((*gly)[0][0] == 0x40);
  assert ((*gly)[1][0] == 0xa0);
  assert ((*gly)[2][0] == 0xe0);
  assert ((*gly)[3][0] == 0x80);
  assert ((*gly)[4][0] == 0x60);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x0041U);
  assert (gly);
  assert ((*gly)[0][0] == 0x40);
  assert ((*gly)[1][0] == 0xa0);
  assert ((*gly)[2][0] == 0xe0);
  assert ((*gly)[3][0] == 0xa0);
  assert ((*gly)[4][0] == 0xa0);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x007dU);
  assert (gly);
  assert ((*gly)[0][0] == 0xc0);
  assert ((*gly)[1][0] == 0x40);
  assert ((*gly)[2][0] == 0x20);
  assert ((*gly)[3][0] == 0x40);
  assert ((*gly)[4][0] == 0xc0);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x007eU);
  assert (gly);
  assert ((*gly)[0][0] == 0x60);
  assert ((*gly)[1][0] == 0xc0);
  assert ((*gly)[2][0] == 0x00);
  assert ((*gly)[3][0] == 0x00);
  assert ((*gly)[4][0] == 0x00);
  assert ((*gly)[5][0] == 0x00);

#ifndef font_default_direct
  gly = find_glyph (0x007fU);
  assert (! gly);
  gly = find_glyph (0x0080U);
  assert (! gly);
  gly = find_glyph (0x009fU);
  assert (! gly);
  gly = find_glyph (0x00a0U);
  assert (! gly);
#endif

#ifndef ASCII
  gly = find_glyph (0x00a1U);
  assert (gly);
  assert ((*gly)[0][0] == 0x80);
  assert ((*gly)[1][0] == 0x00);
  assert ((*gly)[2][0] == 0x80);
  assert ((*gly)[3][0] == 0x80);
  assert ((*gly)[4][0] == 0x80);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x00a2U);
  assert (gly);
  assert ((*gly)[0][0] == 0x40);
  assert ((*gly)[1][0] == 0xe0);
  assert ((*gly)[2][0] == 0x80);
  assert ((*gly)[3][0] == 0xe0);
  assert ((*gly)[4][0] == 0x40);
  assert ((*gly)[5][0] == 0x00);

  gly = find_glyph (0x00ffU);
  assert (gly);
  assert ((*gly)[0][0] == 0xa0);
  assert ((*gly)[1][0] == 0x00);
  assert ((*gly)[2][0] == 0xa0);
  assert ((*gly)[3][0] == 0x60);
  assert ((*gly)[4][0] == 0x20);
  assert ((*gly)[5][0] == 0x40);

# ifndef font_default_direct
  gly = find_glyph (0x0100U);
  assert (! gly);
  gly = find_glyph (0x0101U);
  assert (! gly);
  gly = find_glyph (0x20aaU);
  assert (! gly);
  gly = find_glyph (0x20abU);
  assert (! gly);
# endif

  gly = find_glyph (0x20acU);
  assert (gly);
  assert ((*gly)[0][0] == 0x60);
  assert ((*gly)[1][0] == 0xe0);
  assert ((*gly)[2][0] == 0xe0);
  assert ((*gly)[3][0] == 0xc0);
  assert ((*gly)[4][0] == 0x60);
  assert ((*gly)[5][0] == 0x00);
#endif

  gly = find_glyph (0x20adU);
  assert (! gly);
  gly = find_glyph (0x20aeU);
  assert (! gly);
  gly = find_glyph (0xfffeU);
  assert (! gly);
  gly = find_glyph (0xffffU);
  assert (! gly);

  return 0;
}
