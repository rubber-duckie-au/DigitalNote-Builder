# Qt6 Probe — `qt6-probe` branch

**This branch is a verification exercise. Do not merge to master.**

It answers one question: **does a static Qt6 `qtbase` build with our flags, per target?**
It does not build the wallet and produces nothing worth keeping. Artifacts are disposable
by design.

---

## Why a branch and not a fork

The wallet's release workflows clone this repo with:

```
git clone https://github.com/DigitalNoteXDN/DigitalNote-Builder.git
```

No `-b` flag, and no ref input exists anywhere in those workflows. They **always** get
`master`. So everything on this branch is invisible to the release flow by construction —
a fork would add merge friction for no extra isolation.

**Two rules while this branch lives:**
1. Do not add a builder-ref input to the release workflows.
2. Do not merge `qt6-probe` to master until the wallet's Qt6 API migration is done and the
   targets you care about build.

---

## Two separable milestones

| | What | Needs |
| --- | --- | --- |
| **M1** | Static Qt6 builds per target | **This branch only. No wallet changes.** |
| **M2** | Wallet compiles against Qt6 | ~48 API sites migrated in the wallet repo |

M1 is what this branch is for, and it can start today. M2 is blocked on `QRegExp` (6),
`QSignalMapper` (5), `endl` (4), `QTextCodec` (3), `SkipEmptyParts` (2), `toTime_t` (2)
and `foreach` (26) across `src/qt/`.

---

## Files on this branch

| File | Purpose |
| --- | --- |
| `compile/qt6.sh` | Static Qt6 build. CMake-based replacement for `compile/qt.sh`. |
| `download_qt6.sh` | Fetches **qtbase only**, not qt-everywhere. |
| `.github/workflows/qt6-probe.yml` | Manual-dispatch probe, one target at a time. |

`compile/qt.sh` and `download.sh` are untouched — the Qt5 build still works exactly as before.

---

## What changed from `qt.sh`, and why

**`./configure` is gone.** Qt6 builds with CMake. Every flag had to be re-expressed:
`-static` → `-DBUILD_SHARED_LIBS=OFF`, `-prefix` → `-DCMAKE_INSTALL_PREFIX`,
`-qt-zlib` and friends → `-DQT_FEATURE_system_*=OFF`, `make` → `cmake --build`.

**We build `qtbase` alone.** `include/app/qt_settings.pri` asks for `core gui widgets network`
— all in qtbase. That makes the entire `-skip qtfoo` list and `patch/exclude_qt.txt`
unnecessary for this build, and cuts build time substantially. (It also lists `printsupport`,
but **zero files in `src/qt/` use `QPrint*`** — that line should be deleted from the wallet,
not satisfied here.)

**All eight `q*_p.h` forwarding patches are dropped, not ported.** `qt.sh:23-32` copied shims
into `QtFontDatabaseSupport`, `QtEventDispatcherSupport` and `QtWindowsUIAutomationSupport`.
Those were internal Qt5 support modules; **Qt6 folded them into QtGui and the platform
plugins and deleted `src/platformsupport/` entirely.** The destination directories do not
exist, so those `cp` lines would *error*, not no-op. Whether static-Windows Qt6 has an
equivalent problem is exactly what target 2 exists to find out.

**The libpng `<fp.h>` sed is dropped.** `qt.sh`'s own comment says to drop it once Qt bundles
libpng ≥ 1.6.40. Qt6 does. Left out rather than carried as a no-op so nobody wonders whether
it is load-bearing.

**`qiosurfacegraphicsbuffer.h` is not carried over.** It is a full modified upstream Qt source
file, not a shim, so it cannot be ported blind — re-derive it against Qt6's cocoa plugin when
you reach the macOS targets.

**`patch/patch-src_dbinc_atomic.h` is unaffected** — it patches Berkeley DB, nothing to do
with Qt.

---

## Cache isolation — the one real footgun

The release CI restores from keys like `linux-x64-libs-v8-${{ hashFiles(...) }}`. If this
probe wrote anything under that namespace, a broken Qt6 tree could be silently restored into
**release** builds, and you would be debugging release failures caused by a probe.

**This workflow writes no cache at all.** Nothing it produces outlives the run. If you ever
add caching here, namespace it `qt6probe-*` and never reuse a release prefix.

---

## How to run

Actions → **Qt6 Probe (throwaway)** → Run workflow → pick a target.

Run them **one at a time**, in this order:

| # | Target | Why this order |
| --- | --- | --- |
| 1 | `linux-x64` | No cross-compile, no platform patches. Does the CMake rewrite work at all? |
| 2 | `windows-x64` | **Highest information.** All 8 retired shims were Windows/font related. |
| 3 | macOS x64 | Where `qiosurfacegraphicsbuffer.h` must be re-derived. Not yet wired. |
| 4 | macOS arm64 | Same toolchain, different arch. Not yet wired. |
| 5 | linux-aarch64 | Hardest — Qt6 cross-compilation needs a **host** Qt build first, which is a structural rewrite of `linux/aarch64/compile_libs.sh`, not a flag change. Not yet wired. |

**Stopping after 2 is a legitimate outcome.** If both pass, the toolchain rewrite is tractable
and you can decide about the rest from a stronger position. If Windows fights, you learned it
in a couple of days rather than three weeks.

Targets 3–5 are deliberately not wired yet — add them once 1 and 2 are understood.

---

## Reading the result

Each run writes a job summary.

**Linux success** — confirm `libQt6Core.a`, `libQt6Gui.a`, `libQt6Widgets.a`, `libQt6Network.a`
are all present.

**Windows success** — the headline result. It means the whole forwarding-shim class of hack is
retired.

**Windows failure naming missing private headers under some `*Support` include path** — that is
the Qt6 analogue of the problem the 8 shims solved. **Record the exact paths**; they are what a
Qt6 patch set would need to target.

---

## Version

Defaults to Qt **6.8.3** (LTS). Override via the workflow input. If you move off 6.8.x, re-check
the feature flag names in `compile/qt6.sh` — Qt6 has renamed some `QT_FEATURE_*` between minor
series.
