#!/bin/bash
set -e
cd "$(dirname "$0")"
LT=$(brew --prefix libtool)
export PATH="$LT/libexec/gnubin:$PATH"
export ACLOCAL_PATH="$LT/share/aclocal:$(brew --prefix)/share/aclocal:$ACLOCAL_PATH"
# jq bundles oniguruma as a git submodule that ships empty in the pinned tree;
# fetch it so the builtin regex engine can be built (needs internet).
[ -f vendor/oniguruma/configure.ac ] || git submodule update --init vendor/oniguruma
[ -f configure ] || autoreconf -fi -I "$LT/share/aclocal"
# --disable-shared statically links libjq (and builtin oniguruma) into the jq
# binary, so ./executable is a standalone Mach-O rather than a libtool wrapper
# that hunts for an uninstalled .libs/libjq.dylib.
./configure --with-oniguruma=builtin --disable-maintainer-mode --disable-shared --enable-static
make -j2
# With --disable-shared the build-root `jq` is the real binary; fall back to the
# .libs target if a libtool wrapper is still emitted.
if file jq | grep -q Mach-O; then cp jq executable; else cp .libs/jq executable; fi
