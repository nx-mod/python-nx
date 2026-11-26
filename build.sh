#!/usr/bin/env bash
set -euo pipefail

PYVER="${PYVER:-3.14.6}"
PYMAJOR="${PYVER%.*}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK:-/tmp/opencode/python-nx-build}"
PREFIX="${DEVKITPRO:-/opt/devkitpro}/portlibs/switch"
HOST="${HOST:-aarch64-none-elf}"

source /etc/profile.d/devkit-env.sh
export DEVKITA64="${DEVKITPRO}/devkitA64"
export PATH="${DEVKITA64}/bin:${DEVKITPRO}/tools/bin:${PATH}"

mkdir -p "$WORK"
cd "$WORK"

TARBALL="Python-${PYVER}.tgz"
if [ ! -f "$TARBALL" ]; then
  curl -fsSL "https://www.python.org/ftp/python/${PYVER}/${TARBALL}" -o "$TARBALL"
fi

if [ ! -x "$WORK/host/bin/python${PYMAJOR}" ]; then
  rm -rf host-src
  mkdir -p host-src
  tar -xzf "$TARBALL" -C host-src --strip-components=1
  ( cd host-src && ./configure --prefix="$WORK/host" --without-ensurepip --disable-test-modules >/dev/null && make -j"${JOBS:-4}" >/dev/null && make install >/dev/null )
fi

export PATH="$WORK/host/bin:$PATH"

rm -rf target
mkdir -p target
tar -xzf "$TARBALL" -C target
cd "target/Python-${PYVER}"

patch -p1 < "$ROOT/patches/switch-python.patch"
cp "$ROOT/patches/pyconfig.h" pyconfig.h

export CONFIG_SITE="$PWD/config.site"
export MODULE_BUILDTYPE=static
export CFLAGS="-g -O2 -ffunction-sections -march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE -D_GNU_SOURCE -I${PREFIX}/include -I${DEVKITPRO}/libnx/include"
export CXXFLAGS="$CFLAGS -fno-rtti -fno-exceptions"
export LDFLAGS="-L${PREFIX}/lib -specs=${DEVKITPRO}/libnx/switch.specs"

./configure --host="$HOST" --build=x86_64-linux-gnu \
  --prefix="$PREFIX" --disable-shared --without-ensurepip \
  --disable-test-modules --disable-ipv6 --without-system-expat \
  --without-system-libmpdec --without-readline \
  --with-build-python="$WORK/host/bin/python${PYMAJOR}"

make -j"${JOBS:-4}" libpython${PYMAJOR}.a

sudo -n install -m644 "libpython${PYMAJOR}.a" "${PREFIX}/lib/" || \
  { echo "Run: sudo install -m644 libpython${PYMAJOR}.a ${PREFIX}/lib/" >&2; exit 1; }

sudo -n mkdir -p "${PREFIX}/include/python${PYMAJOR}" || true
sudo -n cp -a Include/. "${PREFIX}/include/python${PYMAJOR}/" || \
  { echo "Run: sudo cp -a Include/. ${PREFIX}/include/python${PYMAJOR}/" >&2; exit 1; }
sudo -n install -m644 pyconfig.h "${PREFIX}/include/python${PYMAJOR}/" || true

( cd Lib && zip -qr "${PREFIX}/lib/python${PYMAJOR}.zip" . -x '__pycache__/*' 'test/*' 'idlelib/*' )

echo "Built and installed libpython${PYMAJOR}.a"
