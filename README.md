# BDF to C in AWK

This is a simplistic [AWK](http://awklang.org/) program, to convert one or more [Adobe BDF](https://www.adobe.com/content/dam/Adobe/en/devnet/font/pdfs/5005.BDF_Spec.pdf) font files (`.bdf`) for an 8 × \_\_ font, into a C module source file (`.c`) or a C header file (`.h`).  The output goes to stdout.

## Usage

  * `bdf2c.awk` [... _options_ ...] [_in.bdf_ ...] [`>` _out.c_]
  * `bdf2c.awk H=1` [... _options_ ...] [_in.bdf_ ...] [`>` _out.h_]

| Option          | Meaning 
| --------------- | -------
| `H=1`           | Output a header file (`.h`) with external references to the code points table and font data.  Default is to output a C source file (`.c`) with the actual data.
| `PUA=0`         | Exclude glyphs in Unicode Private Use Areas.
| `SP=0`          | Exclude glyphs in Unicode supplementary planes.
| `BRAILLE=0`     | Exclude glyphs in Unicode's Braille Patterns block.
| `N=`_font-name_ | Set the font name to use when defining the C constants.  _font-name_ should comprise C identifier characters.

## License

`bdf2c.awk` is distributed under the [GNU General Public License version 2](LICENSE) or above.
