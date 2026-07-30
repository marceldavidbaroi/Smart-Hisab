#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"

cd "$MOBILE"

if [[ ! -d node_modules ]]; then
  echo "Installing mobile deps..."
  pnpm install
fi

if [[ ! -d android ]]; then
  echo "Generating android/ (expo prebuild)..."
  pnpm exec expo prebuild --platform android
fi

# Launch Android Studio with the native project (reuses instance if already open)
open -a "Android Studio" "$MOBILE/android"

echo "Android Studio: $MOBILE/android"
echo "Start Metro separately: pnpm --filter @smart-hisab/mobile start"
