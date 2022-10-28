# BDF to C in AWK

This is a simplistic [AWK](http://awklang.org/) program, to convert one or more [Adobe BDF](https://www.adobe.com/content/dam/Adobe/en/devnet/font/pdfs/5005.BDF_Spec.pdf) font files (`.bdf`) for an 8 × \_\_ font, into a C module source file (`.c`) or a C header file (`.h`).  The output goes to stdout.

On default, `bdf2c.awk` outputs an array of `char32_t` Unicode code points, along with a matching array of glyphs.

## Usage

  * `bdf2c.awk` [... _options_ ...] [_in.bdf_ ...] [`>` _out.c_]
  * `bdf2c.awk H=1` [... _options_ ...] [_in.bdf_ ...] [`>` _out.h_]

| Option          | Meaning 
| --------------- | -------
| `H=1`           | Output a header file (`.h`) with external references to the code points table and font data.  Default is to output a C source file (`.c`) with the actual data.
| `S=1`           | Output 16-bit code points (`char16_t`), not 32-bit ones (`char32_t`).  This implies `SP=0` (see below).
| `D=1`           | Output an array of differences between code points and glyph positions — which should be easier to compress, but just as searchable — instead of an array of code points.
| `SPARSE=1`      | Output only a single sparse array of glyphs, indexed by code point.
| `COSMO=1`       | In the output, do not `#include` standard headers such as `<inttypes.h>`.
|                 |
| `N=`_font-name_ | Set the font name to use when defining the C constants.  _font-name_ should comprise C identifier characters.
| `X=`_prefix_    | Prefix for externally visible C identifiers.  _prefix should comprise C identifier characters.
| `C=`_comments_  | Extra comments to include in C code.
|                 |
| `NONASCII=0`    | Exclude all glyphs not in the printable ASCII range.
| `NONCP437=0`    | Exclude glyphs which do not map easily to the classical Code Page 437 character set ([1](https://learn.microsoft.com/en-us/previous-versions/cc195060(v=msdn.10)?redirectedfrom=MSDN), [2](https://www.unicode.org/Public/MAPPINGS/VENDORS/MISC/IBMGRAPH.TXT)).
| `NONWGL4=0`     | Exclude (most) glyphs not in Microsoft's [Windows Glyph List 4](https://learn.microsoft.com/en-us/typography/opentype/otspec180/wgl4).
| `PUA=0`         | Exclude glyphs in Unicode Private Use Areas.
| `SP=0`          | Exclude glyphs in Unicode supplementary planes.
| `BRAILLE=0`     | Exclude glyphs in Unicode's Braille Patterns block.

## License

`bdf2c.awk` is distributed under the [3-clause BSD License](LICENSE).
