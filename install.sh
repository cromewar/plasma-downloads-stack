#!/bin/sh
# Downloads Stack — installer for the KDE Plasma 6 widget.
#
# Run from a clone:
#     ./install.sh
# Or straight from the internet:
#     curl -fsSL https://raw.githubusercontent.com/cromewar/plasma-downloads-stack/main/install.sh | sh
set -eu

ID="com.cromewar.downloadsstack"
REPO="cromewar/plasma-downloads-stack"
BRANCH="main"

# kpackagetool6 is required (Plasma 6).
if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 not found. This widget needs KDE Plasma 6." >&2
    exit 1
fi

# Find the package: prefer a local clone, otherwise download the repo.
PKG=""
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/package/metadata.json" ]; then
    PKG="$SELF_DIR/package"
else
    echo "Downloading Downloads Stack…"
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP"
    PKG=$(find "$TMP" -maxdepth 2 -type d -name package | head -n 1)
fi

if [ -z "$PKG" ] || [ ! -f "$PKG/metadata.json" ]; then
    echo "Error: could not locate the widget package." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
    echo "Upgrading Downloads Stack…"
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG"
else
    echo "Installing Downloads Stack…"
    kpackagetool6 --type Plasma/Applet --install "$PKG"
fi

echo
echo "Installed. Add it: right-click your panel -> Add Widgets... -> search \"Downloads Stack\"."
echo "If it doesn't show up yet: systemctl --user restart plasma-plasmashell.service"
