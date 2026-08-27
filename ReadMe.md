## DigitalNote-Builder

This is a project to eazily build the qt-wallet and the daemon statically.

Follow the instructions for:
* Windows (64 bits): [windows/x64/ReadMe.md](windows/x64/ReadMe.md)
* Linux (64 bits): [linux/x64/ReadMe.md](linux/x64/ReadMe.md)
* Linux (arm64/aarch64): [linux/aarch64/ReadMe.md](linux/aarch64/ReadMe.md)
* MacOS (Intel): [macos/x64/ReadMe.md](macos/x64/ReadMe.md)
* MacOS (Apple Silicon): [macos/arm64/ReadMe.md](macos/arm64/ReadMe.md)

## Qt6 (v2.0.0.9)

All five targets build against **static Qt6 6.8.3**. `compile/qt.sh` (Qt5) is retained
for reference but is no longer called by any platform.

Two scripts, and **both are required**:

| Script | Provides |
| --- | --- |
| `compile/qt6.sh` | qtbase -- core / gui / widgets / network |
| `compile/qt6_tools.sh` | qttools -- **`lrelease`** |

`qt6_tools.sh` is not optional. `include/app/qt_settings.pri` sets `CONFIG += lrelease`, and
the `.qm` files it produces are **gitignored build artifacts** -- a fresh clone has none, so
`src/qt/bitcoin.qrc` cannot resolve its translation entries without it. Qt5 got `lrelease`
for free from qt-everywhere; qtbase alone does not include it.

**One download step, as documented in the per-platform ReadMes:** `./download.sh` fetches
everything, Qt6 included. There is no separate Qt6 download script -- it was folded in so the
documented flow (`./download.sh` -> `update.sh` -> `compile_libs.sh`) stays a single path.

`wget -c` means it resumes partial downloads and skips complete ones, so it is safe to re-run.

Qt5 is still fetched as a fallback while the migration is verified; drop that line and
`compile/qt.sh` together once it is signed off.

### Platform notes

- **windows/x64** -- `-G Ninja`. `compile/qt6.sh` pins `CMAKE_RC_COMPILER` from `$MINGW_PREFIX`
  because a local msys2 shell may resolve `windres` to `/usr/bin` (MSYS binutils) rather than
  `/mingw64/bin`, which mishandles Qt's quoted defines.
- **macos/x64, macos/arm64** -- `-DFEATURE_framework=OFF`. macOS Qt6 builds frameworks by
  default even when static; this keeps the `.a` layout the other platforms produce.
- **linux/aarch64** -- **builds Qt6 TWICE.** Qt6 cross-compilation needs a HOST Qt6 first,
  because the target build runs `moc`/`rcc`/`uic`, which cannot execute on aarch64. Stage 1
  installs to `libs-host/`, stage 2 cross-builds against it via `QT_HOST_PATH`. Roughly double
  the wall time. **`compile_app.sh` puts the HOST prefix on PATH**, not the target one -- a
  cross-built `lrelease` cannot run on the build machine.

### Retired patches

Every Qt patch in `patch/` is **obsolete under Qt6** and none are applied: the eight
`q*_p.h` forwarders targeted Qt5-internal `*Support` modules that Qt6 deleted, and
`qiosurfacegraphicsbuffer.h` proved unnecessary. Only `patch-src_dbinc_atomic.h` is still
live -- it patches Berkeley DB, not Qt.
