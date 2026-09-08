#!/usr/bin/env bash
# Smoke-test a built mcap-cli closure: the binary is named `mcap`, it runs, it
# reports the version package.nix declares, and shell completions are installed.
#
# Reading the expected version out of package.nix is what makes an automated
# version bump self-verifying: the bump job builds and runs this, so a bump that
# does not actually move the binary fails before it is pushed.
#
# The version assertion anchors rather than searching. `mcap --version` prints
# "mcap <version> (<short sha>) mcap-rust/<library version>" — build.rs embeds the
# commit via .gitattributes export-subst — so an exact comparison fails on the
# provenance suffix, but a bare substring search is worse: that suffix carries a
# second version number, so a stale binary would pass whenever the bumped version
# happened to match the library version it already reports. Match the CLI version
# in the position clap prints it, immediately after the binary name.
#
# Usage: ci/smoke-test.sh [result-path]   (default: ./result)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
result="${1:-$root/result}"

expected="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$root/package.nix" | head -1)"
if [ -z "$expected" ]; then
  echo "FAIL: no version = \"...\"; line found in package.nix" >&2
  exit 1
fi

bin="$result/bin/mcap"
if [ ! -x "$bin" ]; then
  echo "FAIL: $bin is missing or not executable" >&2
  ls -la "$result/bin" >&2 || true
  exit 1
fi

reported="$("$bin" --version)"
echo "package.nix declares: $expected"
echo "mcap --version says:  $reported"
case "$reported" in
"mcap $expected" | "mcap $expected "*) ;;
*)
  echo "FAIL: --version does not report mcap $expected" >&2
  exit 1
  ;;
esac

"$bin" --help >/dev/null
echo "OK: mcap --help exits cleanly"

for completion in \
  share/bash-completion/completions/mcap.bash \
  share/zsh/site-functions/_mcap \
  share/fish/vendor_completions.d/mcap.fish; do
  if [ ! -s "$result/$completion" ]; then
    echo "FAIL: missing or empty completion $completion" >&2
    exit 1
  fi
  echo "OK: $completion"
done

echo "OK: mcap $expected"
