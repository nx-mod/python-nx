# python-nx

Static CPython 3.14.6 for Nintendo Switch homebrew (devkitA64 / libnx), built
for the Kodi-NX port. Based on the `PyNeXt` Switch build and the Switch 2 Kodi
port's Python patches, adapted for Switch 1 and a pthread/newlib toolchain.

## Build

```
./build.sh
```

This builds a matching host CPython, cross-builds a static `libpython3.14.a`,
and installs it plus headers and the standard-library zip into
`$DEVKITPRO/portlibs/switch`.

Requires devkitA64, libnx, and the usual Switch portlibs.

## Contents

- `patches/switch-python.patch` — configure/host fixes and `__SWITCH__` source
  changes for CPython 3.14.6.
- `patches/pyconfig.h` — Switch platform configuration.

## Notes

No dynamic loading is used; extension modules are compiled into the archive.
The standard library is packaged as a zip for the SD card. Credits to the
original PyNeXt and kodi-ns2 projects; this repo hosts only the adapted build.
