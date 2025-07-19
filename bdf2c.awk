#!/usr/bin/awk -f
# Copyright (c) 2020--2025 TK Chia
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the developer(s) nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function error(msg)
{
	err_msg = "line " NR ": " msg
	exit 1
}

function mergesort(src, dest, lo, hi, \
		   mid, i, j, k, tmp)
{
	if (lo == hi) {
		dest[lo] = src[lo]
		return
	}
	mid = int((lo + hi) / 2)
	mergesort(src, tmp, lo, mid)
	mergesort(src, tmp, mid + 1, hi)
	i = lo
	j = lo
	k = mid + 1
	while (i <= hi) {
		if (j <= mid && k <= hi) {
			if (tmp[j] < tmp[k]) {
				dest[i] = tmp[j]
				j += 1
			} else {
				dest[i] = tmp[k]
				k += 1
			}
		} else if (j <= mid) {
			dest[i] = tmp[j]
			j += 1
		} else {
			dest[i] = tmp[k]
			k += 1
		}
		i += 1
	}
}

function new_char()
{
	curr_height = 0
	rows_left = 0
	curr_code = -1
	curr_bitmap = ""
}

# One True Awk 20180827 (mis)parses `0xff' as `0' `xff', i.e. a string
# concatenation operation.  Work around this.
function hex(digits, \
	     value, i, d, n, a)
{
	if (cached_hex_value[digits] != "")
		return cached_hex_value[digits]
	if (cached_hex_value["1"] != 1) {
		a = "0123456789abcdef"
		for (i = 0; i < 16; i += 1) {
			d = substr(a, i + 1, 1)
			cached_hex_value[d] = i
			cached_hex_value[toupper(d)] = i
		}
	}
	value = 0
	n = length(digits)
	for (i = 1; i <= n; i += 1) {
		d = substr(digits, i, 1)
		value *= 16
		value += cached_hex_value[d]
	}
	cached_hex_value[digits] = value
	return value
}

function help()
{
	print "bdf2c.awk -- convert .bdf font files to C modules or headers" \
	      >"/dev/stderr"
	print "  https://codeberg.org/tkchia/bdf2c-in-awk" >"/dev/stderr"
	print "usage:" >"/dev/stderr"
	print "  bdf2c.awk [(options)] [(in.bdf) ...] [> (out.c)]" \
	      >"/dev/stderr"
	print "  bdf2c.awk H=1 [(options)] [(in.bdf) ...] [> (out.h)]" \
	      >"/dev/stderr"
	error("invalid arguments")
}

function init_stdin()
{
	if (ARGC > 1)
		return
	"tty 2>/dev/null" | getline
	if ($0 ~ /^\/dev\//)
		help()
}

function do_init_cp437_map(u1, u2, u3, u4)
{
	is_cp437[hex(u1)] = is_cp437[hex(u2)] = 1
	is_cp437[hex(u3)] = is_cp437[hex(u4)] = 1
}

function init_cp437_map( \
			i, e)
{
	e = hex("007e")
	for (i = 0; i <= e; i += 1)
		is_cp437[i] = 1
	do_init_cp437_map("00a0",  "263a", "236b", "2665")
	do_init_cp437_map("2666",  "2663", "2660", "2022")
	do_init_cp437_map("25d8",  "25cb", "25d9", "2642")
	do_init_cp437_map("2640",  "266a", "266b", "263c")
	do_init_cp437_map("25ba",  "25c4", "2195", "203c")
	do_init_cp437_map("00b6",  "00a7", "25ac", "21a8")
	do_init_cp437_map("2191",  "2193", "2192", "2190")
	do_init_cp437_map("221f",  "2194", "25b2", "25bc")
	do_init_cp437_map("201c",  "201d", "2018", "2019")  # quotation marks
	do_init_cp437_map("2047",  "00a6", "2302", "0394")  # ?, |, house
	do_init_cp437_map("00c7",  "00fc", "00e9", "00e2")
	do_init_cp437_map("00e4",  "00e0", "00e5", "00e7")
	do_init_cp437_map("00ea",  "00eb", "00e8", "00ef")
	do_init_cp437_map("00ee",  "00ec", "00c4", "00c5")
	do_init_cp437_map("00c9",  "00e6", "00c6", "00f4")
	do_init_cp437_map("00f6",  "00f2", "00fb", "00f9")
	do_init_cp437_map("00ff",  "00d6", "00dc", "00a2")
	do_init_cp437_map("00a3",  "00a5", "20ac", "0192")
	do_init_cp437_map("0000",  "2205", "2400", "20a7")  # null, peseta
	do_init_cp437_map("00e1",  "00ed", "00f3", "00fa")
	do_init_cp437_map("00f1",  "00d1", "00aa", "00ba")
	do_init_cp437_map("00bf",  "2310", "00ac", "00bd")
	do_init_cp437_map("00bc",  "00a1", "00ab", "00bb")
	do_init_cp437_map("2591",  "2592", "2593", "2502")
	do_init_cp437_map("2524",  "2561", "2562", "2556")
	do_init_cp437_map("2555",  "2563", "2551", "2557")
	do_init_cp437_map("255d",  "255c", "255b", "2510")
	do_init_cp437_map("2514",  "2534", "252c", "251c")
	do_init_cp437_map("2500",  "253c", "255e", "255f")
	do_init_cp437_map("255a",  "2554", "2569", "2566")
	do_init_cp437_map("2560",  "2550", "256c", "2567")
	do_init_cp437_map("2568",  "2564", "2565", "2559")
	do_init_cp437_map("2558",  "2552", "2553", "256b")
	do_init_cp437_map("256a",  "2518", "250c", "2588")
	do_init_cp437_map("2584",  "258c", "2590", "2580")
	do_init_cp437_map("03b1",  "00df", "0393", "03c0")
	do_init_cp437_map("23ae",  "03b2", "03a0", "220f")  # integral extn.,
							    # beta, pi
	do_init_cp437_map("03a3",  "03c3", "03bc", "03c4")
	do_init_cp437_map("03a6",  "0398", "03a9", "03b4")
	do_init_cp437_map("2211",  "00b5", "2126", "2202")  # Sigma, mu, Omega,
							    # delta
	do_init_cp437_map("221e",  "03c6", "03b5", "2229")
	do_init_cp437_map("03d5", "1d719", "2208", "220a")  # phi, epsilon
	do_init_cp437_map("2261",  "00b1", "2265", "2264")
	do_init_cp437_map("2320",  "2321", "00f7", "2248")
	do_init_cp437_map("00b0",  "2219", "00d7", "221a")
	do_init_cp437_map("207f",  "00b2", "25a0", "03bb")
	do_init_cp437_map("017f",  "00b7", "2713", "266c")  # long s, inter-
							    # punct, check
							    # mark, semiquavers
}

function tidy_args( \
		   i, j, arg)
{
	args = ""
	for (i = 1; i < ARGC; i += 1) {
		arg = ARGV[i]
		if (arg ~ /^C=/)
			args = args " C=..."
		else {
			j = index(arg, "/")
			if (!j)
				args = args " " arg
			else {
				do {
					arg = substr(arg, j + 1)
					j = index(arg, "/")
				} while (j != 0)
				args = args " .../" arg
			}
		}
	}
}

BEGIN {
	init_stdin()
	init_cp437_map()
	err_msg = ""
	n_codes = 0
	max_height = 0
	comments = ""
	max_code = 0
	min_code = ""
	new_char()
}

(NR == 1) {
	H += 0
	S += 0
	D += 0
	SPARSE += 0
	COSMO += 0
	if (NONASCII == "")
		NONASCII = 1
	NONASCII += 0
	if (NONCP437 == "")
		NONCP437 = 1
	NONCP437 += 0
	if (NONWGL4 == "")
		NONWGL4 = 1
	NONWGL4 += 0
	if (PUA == "")
		PUA = 1
	PUA += 0
	if (S)
		SP = 0
	else {
		if (SP == "")
			SP = 1
		SP += 0
	}
	if (BRAILLE == "")
		BRAILLE = 1
	BRAILLE += 0
}

/^[ \t]*(COMMENT|COPYRIGHT|HOMEPAGE|NOTICE)$/ {
	sub(/^[ \t]+/, "")
	gsub(/\*\//, "*\\/")
	comments = comments "\n * " $0
}

/^[ \t]*(COMMENT|COPYRIGHT|HOMEPAGE|NOTICE)[ \t]/ {
	sub(/^[ \t]+/, "")
	gsub(/\*\//, "*\\/")
	comments = comments "\n * " $0
}

/^[ \t]*[0123456789abcdefABCDEF]+[ \t]*$/ {
	if (rows_left) {
		rows_left -= 1
		if (length($1) != 2)
			error("bitmap too wide or too narrow")
		bits = hex($1)
		line = " */\n"
		for (i = 0; i < 8; i += 1) {
			line = (bits % 2 ? "#" : ".") line
			bits = int(bits / 2)
		}
		line = "    0x" tolower($1) ", /* " line
		curr_bitmap = curr_bitmap line
		next
	}
}

/^[ \t]*ENCODING[ \t]+/ {
	curr_code = $2 + 0
	if (curr_code < 0)
		error("bad code point " curr_code)
	next
}

/^[ \t]*BBX[ \t]+/ {
	curr_width = $2 + 0
	if (curr_width == 0)
		error("bitmap width bogus")
	if (curr_width > 8)
		error("bitmap is too wide!")
	curr_height = $3 + 0
	if (curr_height == 0)
		error("bitmap height bogus")
	if (curr_height > max_height)
		max_height = curr_height
	next
}

/^[ \t]*BITMAP[ \t]*$/ {
	if (curr_height == 0)
		error("bitmap height undefined")
	rows_left = curr_height
	next
}

/^[ \t]*ENDCHAR[ \t]*$/ {
	if (curr_code < 0)
		error("code point undefined")
	if (curr_bitmap == "")
		error("bitmap undefined")
	if (!NONASCII && (curr_code < hex("20") || curr_code > hex("7f"))) {
		new_char()
		next
	}
	if (!NONCP437 && !(curr_code in is_cp437)) {
		new_char()
		next
	}
	if (!NONWGL4) {
		wgl4 = 0
		if ((curr_code >= hex("0020") && curr_code <= hex("01ff")) ||
		    (curr_code >= hex("02c0") && curr_code <= hex("02df")) ||
		    (curr_code >= hex("0380") && curr_code <= hex("03cf")) ||
		    (curr_code >= hex("0400") && curr_code <= hex("049f")) ||
		    (curr_code >= hex("1e80") && curr_code <= hex("266f")) ||
		    (curr_code >= hex("f001") && curr_code <= hex("f002")) ||
		    (curr_code >= hex("fb01") && curr_code <= hex("fb02")))
			wgl4 = 1
		if (!wgl4) {
			new_char()
			next
		}
	}
	if (!SP && curr_code > hex("ffff")) {
		new_char()
		next
	}
	if (!PUA && ((curr_code >= hex("00e000") &&
		      curr_code <= hex("00f8ff")) ||
		     (curr_code >= hex("0f0000") &&
		      curr_code <= hex("0ffffd")) ||
		     (curr_code >= hex("100000") &&
		      curr_code <= hex("10fffd")))) {
		new_char()
		next
	}
	if (!BRAILLE && (curr_code >= hex("2800") && curr_code <= hex("28ff")))
	{
		new_char()
		next
	}
	if (code_seen[curr_code])
		error("code point " curr_code " appears more than once")
	n_codes += 1
	codes[n_codes] = curr_code
	code_seen[curr_code] = 1
	bitmap[curr_code] = curr_bitmap
	if (max_code < curr_code)
		max_code = curr_code
	if (min_code == "" || min_code > curr_code)
		min_code = curr_code
	new_char()
	next
}

/^[ \t]*ENDFONT[ \t]*$/ {
	nextfile
}

END {
	if (err_msg == "" && n_codes == 0)
		err_msg = "empty font"
	if (err_msg != "") {
		print "error: " err_msg >"/dev/stderr"
		exit 1
	}
	mergesort(codes, codes, 1, n_codes)
	if (N == "")
		N = "default"
	tidy_args()
	print "/* ****** AUTOMATICALLY GENERATED ******"
	print " * by bdf2c-in-awk  https://gitlab.com/tkchia/bdf2c-in-awk"
	print " *"
	print " * Command line arguments:"
	print " *" args
	if (comments != "") {
		print " * "
		print " * Font information:" comments
	}
	if (C != "") {
		gsub(/\n/, "\n * + ", C)
		gsub(/\*\//, "*\\/", C)
		print " * "
		print " * Extra comments:"
		print " * + " C
	}
	print " */"
	if (S)
		code_type = "char16_t"
	else
		code_type = "char32_t"
	if (H) {
		print "#ifndef H_FONT_" toupper(N)
		print "#define H_FONT_" toupper(N)
		if (!COSMO) {
			print "#include <inttypes.h>"
			if (!SPARSE)
				print "#include <uchar.h>"
		}
		print "#define FONT_" toupper(N) "_GLYPHS " n_codes
		print "#define FONT_" toupper(N) "_WIDTH 8"
		print "#define FONT_" toupper(N) "_HEIGHT " max_height
		if (SPARSE) {
			print "#define FONT_" toupper(N) "_DIRECT_OFFSET " \
			      min_code
			print "extern const uint8_t " X "font_" N "_direct[" \
						    (max_code - min_code + 1) \
						    "][" max_height "];"
		} else {
			if (D)
				print "extern const " code_type " " \
					  X "font_" N "_code_glyph_diffs[" \
						      n_codes "];"
			else
				print "extern const " code_type " " \
					  X "font_" N "_code_points[" \
						      n_codes "];"
			print "extern const uint8_t " \
				  X "font_" N "_data[" n_codes "][" \
						       max_height "];"
		}
		print "#endif"
	} else {
		if (!COSMO)
			print "#include <inttypes.h>"
		if (SPARSE) {
			print "const uint8_t " X "font_" N "_direct[" \
					       (max_code - min_code + 1) "][" \
					       max_height "] = {"
			for (i = 1; i <= n_codes; i += 1) {
				curr_code = codes[i]
				print "  [" (curr_code - min_code) \
					"] = { /* " curr_code " */"
				print bitmap[curr_code] "  },"
			}
			print "};"
		} else {
			if (D) {
				print "#include <uchar.h>"
				print "const " code_type " " \
				      X "font_" N "_code_glyph_diffs[" \
						  n_codes "] = {"
				for (i = 1; i <= n_codes; i += 1)
					print "  " (codes[i] - (i - 1)) ","
				print "};"
			} else {
				print "const " code_type " " \
				      X "font_" N "_code_points[" n_codes \
							      "] = {"
				for (i = 1; i <= n_codes; i += 1)
					print "  " codes[i] ","
				print "};"
			}
			print "const uint8_t " X "font_" N "_data[" n_codes \
					       "][" max_height "] = {"
			for (i = 1; i <= n_codes; i += 1) {
				curr_code = codes[i]
				print "  { /* " curr_code " */"
				print bitmap[curr_code] "  },"
			}
			print "};"
		}
	}
}
