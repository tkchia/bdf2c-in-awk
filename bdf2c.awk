#!/usr/bin/awk -f
# Copyright (c) 2020--2022 TK Chia
#
# This file is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

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

function basename(path, \
		  i)
{
	i = index(path, "/")
	while (i != 0) {
		path = substr(path, i + 1)
		i = index(path, "/")
	}
	return path
}

BEGIN {
	H += 0
	if (NONASCII == "")
		NONASCII = 1
	NONASCII += 0
	if (PUA == "")
		PUA = 1
	PUA += 0
	if (SP == "")
		SP = 1
	SP += 0
	if (BRAILLE == "")
		BRAILLE = 1
	BRAILLE += 0
	comments = ""
	err_msg = ""
	n_codes = 0
	max_height = 0
	new_char()
}

/^[ \t]*(COMMENT|COPYRIGHT)$/ {
	sub(/^[ \t]+/, "")
	comments = comments "\n * " $0
}

/^[ \t]*(COMMENT|COPYRIGHT)[ \t]/ {
	sub(/^[ \t]+/, "")
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
	print "/* ****** AUTOMATICALLY GENERATED ******"
	print " * by bdf2c-in-awk  https://gitlab.com/tkchia/bdf2c-in-awk"
	print " * from " basename(FILENAME)
	if (comments != "") {
		print " * "
		print " * Font information:" comments
	}
	print " */"
	if (H) {
		print "#ifndef H_FONT_" toupper(N)
		print "#define H_FONT_" toupper(N)
		print "#include <inttypes.h>"
		print "#include <wchar.h>"
		print "#define FONT_" toupper(N) "_GLYPHS " n_codes
		print "#define FONT_" toupper(N) "_WIDTH 8"
		print "#define FONT_" toupper(N) "_HEIGHT " max_height
		print "extern const wchar_t " \
			  "font_" N "_code_points[" n_codes "];"
		print "extern const uint8_t " \
			  "font_" N "_data[" n_codes "][" max_height "];"
		print "#endif"
	} else {
		print "#include <inttypes.h>"
		print "#include <wchar.h>"
		print "const wchar_t font_" N "_code_points[" n_codes "] = {"
		for (i = 1; i <= n_codes; i += 1)
			print "  " codes[i] ","
		print "};"
		print "const uint8_t font_" N "_data[" n_codes \
						       "][" max_height "] = {"
		for (i = 1; i <= n_codes; i += 1) {
			curr_code = codes[i]
			print "  { /* " curr_code " */"
			print bitmap[curr_code], "  },"
		}
		print "};"
	}
}
