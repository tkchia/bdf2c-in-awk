#!/bin/sh
# © 2025 TK Chia
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Script to do automated testing under AppVeyor CI (https://ci.appveyor.com/),
# invoked by .appveyor.yml .

set -e -x
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
	  rm -rf "$CSRC" "$CHDR" "$COBJ"
	  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID "$FONT" >"$CSRC"
	  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID H=1 "$FONT" >"$CHDR"
	  for CC in gcc chibicc; do
	    rm -rf "$COBJ"
	    "$CC" -I. -c -O -o "$COBJ" "$CSRC"
	    rm -rf "$COBJ"
	    # As of writing (Sep 2025), chibicc knows about -ffreestanding
	    # but ignores it...
	    "$CC" -I. -c -O -ffreestanding -o "$COBJ" "$CSRC"
	    rm -rf "$PROG"
	    "$CC" -I. -DCHDR="\"$CHDR\"" -O -o "$PROG" tests/main.c "$CSRC"
	    "$PROG"
	  done
	done
	for OFMT in "D=1 R=1" "D=1 SPARSE=1" "R=1 SPARSE=1"; do
	  # These commands should yield an error...
	  if "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID "$FONT" \
	      || "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID H=1 "$FONT"; then
	    echo "FAIL: did not reject bad options!" >&2
	    exit 1
	  fi
	done
      done
    done
  done
done
rm -rf "$OUTDIR"
