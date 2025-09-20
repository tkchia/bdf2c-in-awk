#!/bin/sh
# © 2025 TK Chia
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
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
  PROG="$OUTDIR"/main
  for WCHR in "" "S=.5" "S=1"; do
    for CSET in "" "NONASCII=0"; do
      for HID in "" "HID=1"; do
	for OFMT in "" "D=1" "R=1" "SPARSE=1"; do
	  rm -rf "$CSRC" "$CHDR"
	  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID "$FONT" >"$CSRC"
	  "$AWK" -f ./bdf2c.awk $WCHR $OFMT $CSET $HID H=1 "$FONT" >"$CHDR"
	  for CC in gcc chibicc; do
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
