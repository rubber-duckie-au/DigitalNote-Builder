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
	# TWO layouts are possible, and run 5 proved it the hard way:
	#   Linux / Windows : lib/libQt6Core.a
	#   macOS (default) : lib/QtCore.framework/QtCore   <- static lib, no .a,
	#                     and NO "Qt6" in the name
	# The macOS build in run 5 was entirely correct; this script's original
	# .a-only test reported all four modules MISSING.  Check both.
	fw="Qt${m#Qt6}"                       # Qt6Core -> QtCore
	flat="$PREFIX/lib/lib${m}.a"
	bundle="$PREFIX/lib/${fw}.framework/${fw}"

	if [ -f "$flat" ]; then
		summary "  ${m}  OK  $(du -h "$flat" 2>/dev/null | cut -f1)"
	elif [ -f "$bundle" ]; then
		summary "  ${m}  OK  $(du -h "$bundle" 2>/dev/null | cut -f1)  (framework layout)"
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

if ls "$PREFIX/lib" 2>/dev/null | grep -qi 'BundledLibjpeg'; then
	summary "JPEG: **bundled** (correct - matches the Qt5 \`-qt-libjpeg\` intent)."
else
	summary "JPEG: **SYSTEM libjpeg was linked.**"
	summary "A static release build must not depend on whatever libjpeg happens"
	summary "to be installed on a CI runner. The correct feature names were"
	summary "identified in run 5 and are now pinned in compile/qt6.sh:"
	summary "\\`FEATURE_system_jpeg\\` / \\`FEATURE_system_png\\` (no \\`lib\\` prefix)."
	summary "If this still fires, check the feature dump in the build output."
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
