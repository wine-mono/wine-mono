#!/usr/bin/env bash
# build-mint.sh
# Purpose:
#   1) Build the Wine-Mono MSI from this repo using `make msi`
#   2) (Optional) Install that MSI into a Wine prefix (no sudo)
#
# Usage:
#   chmod +x build-mint.sh
#   ./build-mint.sh
#
#   Optional flags:
#     --jobs N            # parallel build jobs (default: number of CPU cores)
#     --install           # after building, install MSI into your Wine prefix
#     --prefix PATH       # choose Wine prefix (default: $HOME/.wine)
#     --msi PATH          # skip build, install this specific MSI path
#     --verbose           # print more info while running
#
# Tips:
#   • Paste into the Terminal with Ctrl+Shift+V
#   • Run from the repository root (where your project's Makefile lives)

set -euo pipefail
# -e : stop on first error
# -u : treat unset variables as errors
# -o pipefail : any failure in a pipeline fails the whole command

# -------------------------
# Config defaults (overridable via flags)
# -------------------------
JOBS="$(nproc)"                 # use all cores by default
DO_INSTALL="false"              # only install if --install was passed
WINEPREFIX_DEFAULT="$HOME/.wine"
WINEPREFIX_CHOSEN="$WINEPREFIX_DEFAULT"
MSI_PATH=""                     # if given via --msi, skip building
VERBOSE="false"

# -------------------------
# Pretty printing helpers
# -------------------------
say()  { printf "\n==> %s\n" "$*"; }
info() { [ "$VERBOSE" = "true" ] && printf "    • %s\n" "$*" || true; }
die()  { printf "ERROR: %s\n" "$*" >&2; exit 1; }

# -------------------------
# Parse flags
# -------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --jobs)     shift; JOBS="${1:-}"; [ -n "${JOBS}" ] || die "--jobs needs a number";;
    --install)  DO_INSTALL="true";;
    --prefix)   shift; WINEPREFIX_CHOSEN="${1:-}"; [ -n "${WINEPREFIX_CHOSEN}" ] || die "--prefix needs a path";;
    --msi)      shift; MSI_PATH="${1:-}"; [ -n "${MSI_PATH}" ] || die "--msi needs a file path";;
    --verbose)  VERBOSE="true";;
    -h|--help)  sed -n '1,80p' "$0"; exit 0;;
    *)          die "Unknown option: $1 (use --help)";;
  esac
  shift
done

# -------------------------
# Safety checks
# -------------------------

# 1) Don't build as root: `make` should not need sudo.
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  die "Do not run this script with sudo. Build as a normal user."
fi

# 2) Ensure we're in a project root that knows `make msi`.
#    We try a dry-run (`-n`) first; it should exit 0 if the target exists.
if [ -z "$MSI_PATH" ]; then
  if [ ! -f Makefile ] && [ ! -f makefile ]; then
    die "No Makefile found. Please run from the repository root."
  fi

  if ! make -n msi >/dev/null 2>&1; then
    die "This project doesn't seem to have a 'msi' target. Check the repo instructions."
  fi
fi

# 3) Check for tools we rely on at runtime.
need() { command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"; }

need make
# If we will actually run Wine installation later, check wine exists:
if [ "$DO_INSTALL" = "true" ]; then
  need wine
fi

# -------------------------
# Build (unless user gave --msi PATH)
# -------------------------
if [ -z "$MSI_PATH" ]; then
  say "Building MSI (no sudo)…"
  info "Parallel jobs: $JOBS"
  make -j"$JOBS" msi
  # ^ We deliberately avoid sudo here. Building should never require root.

  # Try to locate the resulting MSI automatically.
  # We search common output locations for a wine-mono*.msi produced by the build.
  say "Looking for built MSI artifact…"
  # Search current repo tree (depth-limited for speed) for .msi built today
  # You can tweak the pattern to match your repo's naming scheme.
  MSI_PATH="$(find . -maxdepth 4 -type f -iname '*.msi' -printf '%T@ %p\n' \
             | sort -nr | awk 'NR==1{print $2}')"

  [ -n "$MSI_PATH" ] || die "Build finished, but no MSI was found. Check your Makefile's output path."
  say "Found MSI: $MSI_PATH"
else
  say "Skipping build, using provided MSI: $MSI_PATH"
  [ -f "$MSI_PATH" ] || die "MSI file not found: $MSI_PATH"
fi

# -------------------------
# Optional install into Wine prefix
# -------------------------
if [ "$DO_INSTALL" = "true" ]; then
  say "Installing MSI into Wine prefix"
  info "WINEPREFIX: $WINEPREFIX_CHOSEN"

  # Initialize the Wine prefix (creates directories, registry, etc.)
  # `wineboot -u` sets up a user prefix if it doesn't exist already.
  WINEPREFIX="$WINEPREFIX_CHOSEN" wineboot -u

  # Install quietly (/qn). Remove /qn if you prefer interactive installer UI.
  WINEPREFIX="$WINEPREFIX_CHOSEN" wine msiexec /i "$MSI_PATH" /qn

  say "MSI installed into: $WINEPREFIX_CHOSEN"
  info "You can change the prefix with: --prefix /path/to/prefix"
else
  say "Build complete ✅"
  info "To install the MSI later into Wine:"
  info "  WINEPREFIX='$WINEPREFIX_DEFAULT' wine msiexec /i '$MSI_PATH' /qn"
fi
