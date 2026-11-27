#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 TAG CHANGELOG PUBSPEC OUTPUT" >&2
  exit 1
fi

tag=$1
changelog=$2
pubspec=$3
output=$4

if [[ ! $tag =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo "Tag '$tag' must be a version such as v1.0.0 or 1.0.0." >&2
  exit 1
fi
version=${tag#v}

awk -v version="$version" -v tag="$tag" -v file="$pubspec" '
  /^version:[ \t]*[^[:space:]#+]+(\+[0-9]+)?[ \t]*(#.*)?\r?$/ {
    value = $0
    sub(/^version:[ \t]*/, "", value)
    sub(/[ \t]*#.*/, "", value)
    sub(/[ \t\r]*$/, "", value)
    sub(/\+[0-9]+$/, "", value)
    count++
    found = value
  }
  END {
    if (count != 1 || found != version) {
      printf "Tag \047%s\047 does not match the app version in \047%s\047.\n", tag, file > "/dev/stderr"
      exit 1
    }
  }
' "$pubspec"

tmp=$(mktemp "${output}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

awk -v version="$version" '
  {
    sub(/\r$/, "")
    if ($0 ~ /^##[ \t]+/) {
      active = 0
      heading = $0
      sub(/^##[ \t]+/, "", heading)
      split(heading, words, /[ \t]+/)
      heading = words[1]
      if (heading ~ /^\[.*\]$/) {
        heading = substr(heading, 2, length(heading) - 2)
      }
      if (heading == version || heading == "v" version) {
        count++
        active = 1
      }
    }
    if (active) text = text $0 "\n"
  }
  END {
    if (count != 1) {
      printf "Expected exactly one changelog section for version \047%s\047; found %d.\n", version, count > "/dev/stderr"
      exit 1
    }
    sub(/[ \t\n]+$/, "", text)
    print text
  }
' "$changelog" > "$tmp"

mv -f -- "$tmp" "$output"
