#!/usr/bin/env bash
# Fails if line coverage of lib/domain/ in coverage/lcov.info is below the threshold.
# Generated files (*.g.dart, *.freezed.dart) are excluded.
# Usage: scripts/check_domain_coverage.sh [threshold_percent] [lcov_file]
set -euo pipefail

threshold="${1:-80}"
lcov_file="${2:-coverage/lcov.info}"

if [[ ! -f "$lcov_file" ]]; then
  echo "error: $lcov_file not found; run 'flutter test --coverage' first" >&2
  exit 1
fi

read -r found hit < <(awk '
  /^SF:/ { in_domain = ($0 ~ /^SF:(.*\/)?lib\/domain\//) && ($0 !~ /\.(g|freezed)\.dart$/) }
  in_domain && /^LF:/ { split($0, a, ":"); found += a[2] }
  in_domain && /^LH:/ { split($0, a, ":"); hit += a[2] }
  END { print found + 0, hit + 0 }
' "$lcov_file")

if (( found == 0 )); then
  echo "error: no lib/domain/ lines found in $lcov_file" >&2
  exit 1
fi

pct=$(awk -v h="$hit" -v f="$found" 'BEGIN { printf "%.2f", (h / f) * 100 }')
echo "Domain coverage: ${pct}% (${hit}/${found} lines), threshold ${threshold}%"

if awk -v p="$pct" -v t="$threshold" 'BEGIN { exit !(p < t) }'; then
  echo "error: domain coverage below ${threshold}%" >&2
  exit 1
fi
