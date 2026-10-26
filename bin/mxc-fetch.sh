#!/bin/bash
set -euo pipefail

# Download the pinned MXC release and extract the Linux executor (lxc-exec)
# to .mxc/lxc-exec. The zip is verified against a SHA-256 pin before use.
# Bump MXC_VERSION + MXC_SHA256 together to upgrade.

MXC_VERSION=v1.0.1
MXC_SHA256=0e832239454ba7fcd338ff56218a287eef4c0a01c1484084b869f55feff8abe9

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT_DIR/.mxc"

case "$(uname -m)" in
    x86_64)  ARCH=x64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "!! unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [ -x "$OUT/lxc-exec" ] && [ "$(cat "$OUT/VERSION" 2>/dev/null)" = "$MXC_VERSION" ]; then
    echo "lxc-exec $MXC_VERSION already present: $OUT/lxc-exec"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/mxc.zip" \
    "https://github.com/microsoft/mxc/releases/download/$MXC_VERSION/mxc-release-binaries.zip"
echo "$MXC_SHA256  $tmp/mxc.zip" | sha256sum -c -

mkdir -p "$OUT"
# -I: isolated mode, nothing from the cwd can shadow the stdlib.
python3 -I - "$tmp/mxc.zip" "$ARCH/lxc-exec" "$OUT" <<'PY'
import sys, zipfile
zf, member, out = sys.argv[1:]
with zipfile.ZipFile(zf) as z:
    z.extract(member, out)
PY
mv "$OUT/$ARCH/lxc-exec" "$OUT/lxc-exec"
rmdir "$OUT/$ARCH"
chmod +x "$OUT/lxc-exec"
echo "$MXC_VERSION" > "$OUT/VERSION"
echo "installed $OUT/lxc-exec ($MXC_VERSION, $ARCH)"
