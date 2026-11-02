#!/bin/bash
set -uo pipefail

fail() {
  printf '%s\n' "$1" >&2
  exit 2
}

if [ "$#" -lt 4 ] || [ "$3" != "--" ]; then
  fail "Usage: $0 ABS_OUTPUT_DIR ABS_BRIEF -- COMMAND [ARGS...]"
fi

output_dir=$1
brief=$2
shift 3

[[ "$output_dir" == /* && "$brief" == /* ]] || fail 'Output directory and brief must be absolute paths.'
[ -d "$output_dir" ] || fail "Output directory does not exist: $output_dir"
[ -f "$brief" ] || fail "Brief does not exist: $brief"
for name in events.jsonl stderr.log exit-code result.md; do
  if [ -e "$output_dir/$name" ] || [ -L "$output_dir/$name" ]; then
    fail "Refusing to overwrite worker output: $output_dir/$name"
  fi
done

# A stopped worker still leaves an exit-code marker, so it never looks like it is still running.
status=interrupted
trap 'printf "%s\n" "$status" > "$output_dir/exit-code"' EXIT
trap 'status=130; exit 130' INT
trap 'status=143; exit 143' TERM

"$@" < "$brief" 2> "$output_dir/stderr.log" | tee "$output_dir/events.jsonl"
statuses=("${PIPESTATUS[@]}")
status=${statuses[0]}
if [ "$status" -eq 0 ] && [ "${statuses[1]}" -ne 0 ]; then
  status=${statuses[1]}
fi
exit "$status"
