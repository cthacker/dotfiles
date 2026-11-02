#!/bin/bash
set -e
set -o pipefail

if [ "$#" -lt 4 ] || [ "$3" != "--" ]; then
  printf 'Usage: %s ABS_OUTPUT_DIR ABS_BRIEF -- COMMAND [ARGS...]\n' "$0" >&2
  exit 2
fi

output_dir=$1
brief=$2
shift 3

if [[ "$output_dir" != /* || "$brief" != /* ]]; then
  printf 'Output directory and brief must be absolute paths.\n' >&2
  exit 2
fi

test -d "$output_dir"
test -f "$brief"
for name in events.jsonl stderr.log exit-code result.md; do
  if [ -e "$output_dir/$name" ] || [ -L "$output_dir/$name" ]; then
    printf 'Refusing to overwrite worker output: %s\n' "$output_dir/$name" >&2
    exit 2
  fi
done

set +e
"$@" < "$brief" 2> "$output_dir/stderr.log" | tee "$output_dir/events.jsonl"
statuses=("${PIPESTATUS[@]}")
status=${statuses[0]}
if [ "$status" -eq 0 ] && [ "${statuses[1]}" -ne 0 ]; then
  status=${statuses[1]}
fi
set -e

printf '%s\n' "$status" > "$output_dir/exit-code"
exit "$status"
