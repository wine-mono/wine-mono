#!/usr/bin/env bash
set -euo pipefail

# === Settings you can tweak ===
CMAKE_VER_MIN="4.1.0"
CMAKE_TARBALL_URL="https://github.com/Kitware/CMake/releases/download/v4.1.0/cmake-4.1.0-linux-x86_64.tar.gz"
CMAKE_INSTALL_DIR="/opt/cmake-4.1.0"      # manual install target
WINEPREFIX_DEFAULT="${HOME}/.wine"        # default Wine prefix
WINE_MONO_URL="${WINE_MONO_URL:-}"        # set to a specific MSI URL to force install, or leave empty to auto-install via wineboot

say() { printf "\n==> %s\n" "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }

sudo_true() {
  if ! sudo -n true 2>/dev/null; then
    say "This script will ask for your password to install packages."
  fi
}

version_ge() { [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

install_base_packages() {
  say "Updating apt and installing base developer tools"
  sudo apt update
  sudo apt install -y \
    build-essential git curl ca-certificates pkg-config \
    autoconf automake libtool m4 gettext
}

ensure_cmake() {
  local need_cmake=true
  if command -v cmake >/dev/null 2>&1; then
    local v
    v="$(cmake --version | sed -n '1s/.*version //p')"
    if version_ge "$v" "$CMAKE_VER_MIN"; then
      say "CMake $v is already ≥ $CMAKE_VER_MIN — skipping manual install"
      need_cmake=false
    fi
  fi

  if $need_cmake; then
    say "Installing CMake ${CMAKE_VER_MIN} to ${CMAKE_INSTALL_DIR}"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    ( cd "$tmp"
      curl -fL -O "$CMAKE_TARBALL_URL"
      tar -xzf "$(basename "$CMAKE_TARBALL_URL")"
      extracted="$(tar -tzf "$(basename "$CMAKE_TARBALL_URL")" | head -1 | cut -d/ -f1)"
      sudo rm -rf "$CMAKE_INSTALL_DIR"
      sudo mv "$extracted" "$CMAKE_INSTALL_DIR"
    )
    # Symlink only cmake/cpack/ctest to avoid clobbering unrelated tools
    for tool in cmake cpack ctest; do
      sudo ln -sf "${CMAKE_INSTALL_DIR}/bin/${tool}" "/usr/local/bin/${tool}"
    done
    say "CMake installed: $(cmake --version | head -n1)"
  fi
}

install_wine() {
  say "Installing Wine (64-bit)"
  sudo apt update
  sudo apt install -y wine winbind
  say "Wine version: $(wine --version || echo 'wine not on PATH?')"
}

init_wine_prefix() {
  local prefix="${1:-$WINEPREFIX_DEFAULT}"
  say "Initializing WINEPREFIX at: ${prefix}"
  WINEPREFIX="$prefix" WINEARCH=win64 wineboot -u
}

install_libgdiplus_from_source() {
  say "Installing libgdiplus build dependencies"
  sudo apt install -y \
    libcairo2-dev libglib2.0-dev libexif-dev libtiff5-dev libjpeg-dev libpng-dev libgif-dev

  say "Cloning and building libgdiplus"
  rm -rf libgdiplus
  git clone --depth=1 https://github.com/mono/libgdiplus.git
  pushd libgdiplus >/dev/null
    ./autogen.sh
    make -j"$(nproc)"
    make check
    sudo make install
  popd >/dev/null
  sudo ldconfig
  say "libgdiplus installed"
}

install_wine_mono_if_requested() {
  local prefix="${1:-$WINEPREFIX_DEFAULT}"
  if [[ -n "$WINE_MONO_URL" ]]; then
    say "Downloading Wine-Mono MSI from: $WINE_MONO_URL"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    ( cd "$tmp"; curl -fLO "$WINE_MONO_URL" )
    local msi="$tmp/$(basename "$WINE_MONO_URL")"
    say "Installing Wine-Mono into ${prefix}"
    WINEPREFIX="$prefix" wine msiexec /i "$msi" /qn
    say "Wine-Mono installation finished."
  else
    say "No WINE_MONO_URL provided. Letting Wine auto-install Mono on first run (recommended)."
  fi
}

main() {
  sudo_true
  install_base_packages
  need curl
  ensure_cmake
  install_wine
  init_wine_prefix "$WINEPREFIX_DEFAULT"
  install_libgdiplus_from_source
  install_wine_mono_if_requested "$WINEPREFIX_DEFAULT"

  say "All done"
  echo
  echo "Tips:"
  echo " - Paste in Terminal with Ctrl+Shift+V"
  echo " - To force Wine-Mono install, re-run with:"
  echo "     WINE_MONO_URL='https://dl.winehq.org/wine/wine-mono/9.0.0/wine-mono-9.0.0-x86.msi' ./dependencies-mint.sh"
}

main "$@"

