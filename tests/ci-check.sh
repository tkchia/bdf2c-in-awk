#!/bin/sh
# © 2025—2026 TK Chia
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Script to do automated testing under AppVeyor CI (https://ci.appveyor.com/),
# invoked by .appveyor.yml .

verbose () {
  local out
  if test x-o = x"$1"; then
    out="$2"
    shift 2
    echo "$@ >$out" >&2
    "$@" >"$out"
  else
    echo "$@" >&2
    "$@"
  fi
}

fail () {
  echo "*** FAIL: $@ ***" >&2
  exit 1
}

pass () {
  echo "*** PASS: $@ ***" >&2
}

set -e
OUTDIR=scratch
rm -rf "$OUTDIR"
mkdir "$OUTDIR"
for AWK in gawk mawk original-awk wak; do
  # https://robey.lag.net/2010/01/23/tiny-monospace-font.html
  # "... Brian has authorized his font to be released under the CC0 or
  # CC-BY 3.0 license.  Therefore, this font may also be used under either
  # CC0 or CC-BY 3.0 license."
  FONT=tests/tom-thumb.bdf
  CSRC="$OUTDIR"/font.c
  CHDR="$OUTDIR"/font.h
  COBJ="$OUTDIR"/font.o
  PROG="$OUTDIR"/main
  for WCHR in "" "S=.5" "S=1"; do
    for CSET in "" "NONASCII=0"; do
      for HID in "" "HID=1"; do
	for OFMT in "" "D=1" "R=1" "SPARSE=1"; do
	  verbose rm -rf "$CSRC" "$CHDR" "$COBJ"
	  verbose -o "$CSRC" \
		  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID "$FONT"
	  if test \! -s "$CSRC"; then
	    fail "bad .c output!"
	  fi
	  verbose -o "$CHDR" \
		  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID H=1 "$FONT"
	  if test \! -s "$CHDR"; then
	    fail "bad .h output!"
	  fi
	  for CC in gcc chibicc kefir; do
	    verbose rm -rf "$COBJ"
	    verbose "$CC" -I. -c -O -o "$COBJ" "$CSRC"
	    verbose rm -rf "$COBJ"
	    # As of writing (Sep 2025), chibicc knows about -ffreestanding
	    # but ignores it...
	    verbose "$CC" -I. -c -O -ffreestanding -o "$COBJ" "$CSRC"
	    verbose rm -rf "$PROG"
	    DCSET=
	    if test "NONASCII=0" = "$CSET"
	      then DCSET=-DASCII; fi
	    verbose "$CC" -I. -DCHDR="\"$CHDR\"" $DCSET -O -o "$PROG" \
		    tests/main.c "$CSRC"
	    verbose "$PROG"
	  done
	done
	for OFMT in "D=1 R=1" "D=1 SPARSE=1" "R=1 SPARSE=1"; do
	  # These commands should yield an error...
	  if verbose "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID "$FONT" \
	      || verbose "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID H=1 \
				"$FONT"; then
	    fail "did not reject bad options!"
	  fi
	  pass "bad options rejected as expected"
	done
	for INTERNAL in "COPYING=CC0-1.0" "ADDR=https://example.com/"; do
	  # ...as should these...
	  if verbose "$AWK" -f ./bdf2c.awk $WCHR $INTERNAL $CSET $HID "$FONT" \
	      || verbose "$AWK" -f ./bdf2c.awk $WCHR $INTERNAL $CSET $HID H=1 \
				"$FONT"; then
	    fail "FAIL: did not reject bad options!"
	  fi
	  pass "bad options rejected as expected"
	done
      done
    done
  done
done
verbose rm -rf "$OUTDIR"
pass ✌️
