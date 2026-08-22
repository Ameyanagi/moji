#!/usr/bin/env bash
set -euo pipefail

block_dir=.pixi/readme-blocks
mkdir -p "$block_dir"

block_count=$(
  awk -v block_dir="$block_dir" '
    BEGIN {
      in_mojo_block = 0
      block_count = 0
    }

    /^```mojo[[:space:]]*$/ {
      if (!in_mojo_block) {
        block_count++
        block_file = block_dir "/block_" block_count ".mojo"
        in_mojo_block = 1
        next
      }
    }

    in_mojo_block && /^```[[:space:]]*$/ {
      close(block_file)
      in_mojo_block = 0
      next
    }

    in_mojo_block {
      print > block_file
    }

    END {
      if (in_mojo_block) {
        print "Unclosed fenced Mojo block in README.md" > "/dev/stderr"
        exit 1
      }
      print block_count
    }
  ' README.md
)

if (( block_count == 0 )); then
  printf 'No fenced Mojo blocks found in README.md\n' >&2
  exit 1
fi

block_number=1
while (( block_number <= block_count )); do
  source_file="$block_dir/block_$block_number.mojo"
  mojo build -I src "$source_file" -o "$block_dir/block_$block_number"
  ((block_number += 1))
done
