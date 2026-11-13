#!/bin/bash
set -euo pipefail

# Type one line into a Codex pane and submit it, once Codex has finished its turn and its input
# box looks empty, so a draft the user has typed there is not sent with it. The check is best
# effort: the user could still start typing in the moment before the ask is sent.
# Waits up to two minutes.
# Usage: ask.sh SESSION BLOCK "MESSAGE"

session=$1
block=$2
message=$3

# Whether Codex's input box is empty. The box starts at the last line that begins with "›" and
# ends at Codex's status line below it ("Context 90% left", "? for shortcuts"). An empty box
# shows a hint in dim text (SGR 2), so the box is empty when every printed character in it after
# the "›" is dim or a space. Anything uncertain, such as no status line, counts as not empty.
input_box_empty() {
  perl -e '
    my @lines = split /\r?\n/, $ARGV[0];
    my ($start) = grep { $lines[$_] =~ /^(\e\[[0-9;?]*[A-Za-z])*\xe2\x80\xba/ }
      reverse 0 .. $#lines;
    exit 1 unless defined $start;
    my ($end) = grep { $lines[$_] =~ /% left|for shortcuts/ } $start + 1 .. $#lines;
    exit 1 unless defined $end;
    my $dim = 0;
    for my $i ($start .. $end - 1) {
      my $line = $lines[$i];
      $line =~ s/^.*?\xe2\x80\xba// if $i == $start;
      for my $part (split /(\e\[[0-9;]*[A-Za-z])/, $line) {
        if ($part =~ /^\e\[([0-9;]*)m$/) {
          my @codes = split /;/, ($1 eq "" ? "0" : $1);
          while (@codes) {
            my $code = shift @codes;
            # 38 and 48 are colours whose own parameters follow; they say nothing about dim.
            if ($code eq "38" || $code eq "48") {
              splice @codes, 0, ($codes[0] // "") eq "2" ? 4 : 2;
            }
            elsif ($code eq "2") { $dim = 1 }
            elsif ($code eq "0" || $code eq "22") { $dim = 0 }
          }
        } elsif ($part !~ /^\e/ && !$dim && $part =~ /\S/) {
          exit 1;
        }
      }
    }
    exit 0;
  ' "$1"
}

SECONDS=0
while [ "$SECONDS" -lt 120 ]; do
  if ! screen=$(rex capture -s "$session" -b "$block" --format=vt); then
    echo "codex: could not read the pane; nothing sent" >&2
    exit 1
  fi
  screen=$(tail -15 <<<"$screen")
  if ! grep -q "esc to interrupt" <<<"$screen" && grep -qa "›" <<<"$screen"; then
    if ! input_box_empty "$screen"; then
      echo "codex: something is typed in the input box; nothing sent" >&2
      exit 1
    fi
    rex send -s "$session" -b "$block" "$message"
    sleep 1
    rex send-key -s "$session" -b "$block" Enter
    echo "codex: sent"
    exit 0
  fi
  sleep 2
done
echo "codex: still busy after two minutes; nothing sent" >&2
exit 1
