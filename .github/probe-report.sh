#! /usr/bin/env bash
#
# .github/probe-report.sh -- shared outcome reporter for the Qt6 probe.
#
# Usage: probe-report.sh "<target label>" "<prefix path>"
#
# Extracted from the workflow because run 4 exposed a bug in the inline
# version: the Windows job's build SUCCEEDED yet the report step still emitted
# "BUILD FAILED", because the path test did not resolve the same way under
# MSYS2 as it did under bash on Linux.  One shared script with one code path
# removes that whole class of divergence, and means a fix lands for all five
# targets at once.
#
# Deliberately NEVER exits non-zero: this runs under `if: always()` and its
# job is to describe what happened, not to decide pass/fail.  The build step
# itself already sets the job status.

TARGET_LABEL="${1:-unknown target}"
PREFIX="${2:-}"

summary() {
	if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
		echo "$1" >> "$GITHUB_STEP_SUMMARY"
	fi
	echo "$1"
}

summary "## Qt6 probe - ${TARGET_LABEL}"
summary ""

if [ -z "$PREFIX" ] || [ ! -d "$PREFIX/lib" ]; then
	summary "**BUILD FAILED** - no lib directory at \`${PREFIX}\`"
	summary ""
	summary "Read the build step output above."
	summary ""
	summary "If the failure names missing private headers under a \`*Support\`"
	summary "include path, that is the Qt6 analogue of the problem the eight"
	summary "retired shims in \`patch/\` solved - record the exact paths."
	summary ""
	summary "If it is a cross-compile failure on aarch64, check that stage 1"
	summary "(host Qt6) completed and that QT_HOST_PATH pointed at it."
	exit 0
fi

# --- required modules ---------------------------------------------------
MISSING=0
summary "### Modules the wallet requires"
summary ""
summary '```'
for m in Qt6Core Qt6Gui Qt6Widgets Qt6Network; do
	if [ -f "$PREFIX/lib/lib${m}.a" ]; then
		sz="$(du -h "$PREFIX/lib/lib${m}.a" 2>/dev/null | cut -f1)"
		summary "  ${m}  OK  ${sz}"
	else
		summary "  ${m}  MISSING"
		MISSING=1
	fi
done
summary '```'
summary ""

if [ "$MISSING" -eq 0 ]; then
	summary "**BUILD SUCCEEDED** - all four required modules present."
else
	summary "**PARTIAL** - lib directory exists but a required module is missing."
fi
summary ""

# --- bundled 3rd-party libs ---------------------------------------------
# Presence proves the bundled feature flags took effect.  Absence of
# libQt6BundledLibjpeg.a specifically is the KNOWN OPEN ISSUE: it means this
# target linked a SYSTEM libjpeg, which the Qt5 build deliberately avoided
# via -qt-libjpeg.  Linux exhibited this in run 2; Windows did not in run 4.
summary "### Bundled 3rd-party libraries"
summary ""
summary '```'
BUNDLED="$(ls "$PREFIX/lib" 2>/dev/null | grep -E '^libQt6Bundled' || true)"
if [ -n "$BUNDLED" ]; then
	echo "$BUNDLED" | while read -r b; do summary "  $b"; done
else
	summary "  (none - every 3rd-party dep came from the system)"
fi
summary '```'
summary ""

if ls "$PREFIX/lib" 2>/dev/null | grep -q '^libQt6BundledLibjpeg'; then
	summary "JPEG: **bundled** (correct - matches the Qt5 \`-qt-libjpeg\` intent)."
else
	summary "JPEG: **SYSTEM libjpeg was linked** - this is the known open issue."
	summary "A static release build must not depend on whatever libjpeg happens"
	summary "to be installed on a CI runner. Check the image-codec feature dump"
	summary "in the build step output for the correct Qt6 feature name to pin."
fi
summary ""

# --- things that should NOT be here --------------------------------------
summary "### Disabled features (expect all absent)"
summary ""
summary '```'
for u in Qt6OpenGL Qt6OpenGLWidgets Qt6Sql Qt6DBus; do
	if [ -f "$PREFIX/lib/lib${u}.a" ]; then
		summary "  ${u}  PRESENT - flag did not take effect"
	else
		summary "  ${u}  absent  OK"
	fi
done
summary '```'
summary ""

exit 0
