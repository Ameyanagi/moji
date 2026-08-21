#!/usr/bin/env bash
set -euo pipefail

for test_file in tests/test_*.mojo; do
  mojo run -I src "$test_file"
done

mkdir -p .pixi/test-bin
for example_file in examples/*.mojo; do
  example_name=$(basename "${example_file%.mojo}")
  mojo build -I src "$example_file" -o ".pixi/test-bin/$example_name"
done

for fixture in tests/compile_fail/*.mojo; do
  fixture_name=$(basename "${fixture%.mojo}")
  diagnostic=".pixi/test-bin/${fixture_name}.log"
  if mojo build -I src "$fixture" -o ".pixi/test-bin/$fixture_name" \
    >"$diagnostic" 2>&1; then
    printf 'Expected compilation failure: %s\n' "$fixture" >&2
    exit 1
  fi
  while IFS= read -r expected; do
    if [[ -n "$expected" ]] && ! grep -Fq -- "$expected" "$diagnostic"; then
      printf 'Missing expected diagnostic %q for %s\n' "$expected" "$fixture" >&2
      cat "$diagnostic" >&2
      exit 1
    fi
  done < "${fixture%.mojo}.expected"
done
