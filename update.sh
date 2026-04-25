#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq nix coreutils gnused gnugrep

# Auto-update script for the FalkorDB Nix package.
# Fetches the latest GitHub release, downloads each platform binary,
# computes SRI hashes, and patches package.nix in-place.

set -euo pipefail

OWNER="FalkorDB"
REPO="FalkorDB"
PACKAGE_NIX="$(cd "$(dirname "$0")" && pwd)/package.nix"

# Map Nix system strings to the GitHub release asset filenames.
declare -A ASSETS=(
  ["aarch64-darwin"]="falkordb-macos-arm64v8.so"
  ["x86_64-linux"]="falkordb-x64.so"
  ["aarch64-linux"]="falkordb-arm64v8.so"
)

# --- Resolve latest version ------------------------------------------------

latest_version=$(
  curl -sf "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
    | jq -r '.tag_name | ltrimstr("v")'
)

current_version=$(
  grep -Po '(?<=version = ")[^"]+' "$PACKAGE_NIX"
)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "Already up to date: v${current_version}"
  exit 0
fi

echo "Updating ${current_version} -> ${latest_version}"

# --- Prefetch each platform binary and collect SRI hashes -------------------

declare -A HASHES

for system in "${!ASSETS[@]}"; do
  asset="${ASSETS[$system]}"
  url="https://github.com/${OWNER}/${REPO}/releases/download/v${latest_version}/${asset}"

  echo "Prefetching ${system} (${asset})..."
  hash=$(nix hash convert --to sri --hash-algo sha256 \
    "$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)")

  HASHES[$system]="$hash"
  echo "  ${system}: ${hash}"
done

# --- Patch package.nix -----------------------------------------------------

# Update the version string.
sed -i.bak "s|version = \"${current_version}\"|version = \"${latest_version}\"|" "$PACKAGE_NIX"

# Update each platform hash.
for system in "${!HASHES[@]}"; do
  # Match the hash line that follows the url line for this system.
  # Uses a two-line sed address: find the system block, then replace the hash.
  old_hash=$(
    sed -n "/\"${system}\"/{n;n;s/.*hash = \"\([^\"]*\)\".*/\1/p}" "$PACKAGE_NIX.bak"
  )
  sed -i "s|${old_hash}|${HASHES[$system]}|" "$PACKAGE_NIX"
done

rm -f "$PACKAGE_NIX.bak"

echo ""
echo "package.nix updated to v${latest_version}"
echo "Run 'nix build' to verify, then commit the changes."
