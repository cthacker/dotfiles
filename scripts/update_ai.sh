#!/bin/bash
# Update every AI/agent CLI installed on this machine.
#
# Deliberately does NOT use `set -e` like the install scripts: one tool failing
# to update must not stop the rest of the herd. Failures are collected and
# reported in the summary, and the script exits non-zero if anything failed.
set -o pipefail

if [ -t 1 ]; then
  BLUE="$(tput setaf 79)"
  GREEN="$(tput setaf 78)"
  YELLOW="$(tput setaf 179)"
  RED="$(tput setaf 197)"
  RESET="$(tput sgr 0)"
else
  BLUE=""
  GREEN=""
  YELLOW=""
  RED=""
  RESET=""
fi

# Order matters only for readability of the output.
ALL_TOOLS="herdr pi omp claude codex grok amp cursor-agent gemini"

UPDATED=""
SKIPPED=""
FAILED=""

usage() {
  cat <<EOF
Usage: update-ai [tool...]

Updates the AI/agent CLIs installed on this machine. With no arguments every
known tool is updated; tools that are not installed are skipped.

Known tools:
  herdr         herdr update
  pi            pi update --all            (pi itself + installed extensions)
  omp           omp update, omp update --plugins
  claude        claude update, claude plugin marketplace update
  codex         brew upgrade --cask codex
  grok          grok update
  amp           amp update
  cursor-agent  cursor-agent update
  gemini        npm install -g @google/gemini-cli@latest (no self-updater)

Options:
  -l, --list    List known tools and whether each is installed
  -h, --help    Show this help
EOF
}

# Find the global npm that actually owns a package. Node CLIs can be installed
# under Homebrew's node or an nvm-managed node, and each has its own global
# prefix, so the wrong npm would silently install a second copy.
find_global_npm() {
  local pkg="$1"
  local candidate
  for candidate in "$(command -v npm 2>/dev/null)" /opt/homebrew/bin/npm /usr/local/bin/npm; do
    [ -n "$candidate" ] && [ -x "$candidate" ] || continue
    if "$candidate" ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# Codex ships as a Homebrew cask rather than a self-updating binary. Only the
# codex cask is touched here: anything else installed via brew stays out of this
# script so nothing gets upgraded invisibly alongside it.
update_codex() {
  brew upgrade --cask codex
}

# Gemini CLI has no self-update subcommand; reinstall it with its owning npm.
update_gemini() {
  local npm_bin
  npm_bin="$(find_global_npm @google/gemini-cli)" || {
    echo "${RED}Could not find the global npm that owns @google/gemini-cli${RESET}" >&2
    return 1
  }
  "$npm_bin" install -g @google/gemini-cli@latest
}

tool_installed() {
  case "$1" in
    codex)
      command -v brew >/dev/null 2>&1 && brew list --cask codex >/dev/null 2>&1
      ;;
    gemini)
      command -v gemini >/dev/null 2>&1 && find_global_npm @google/gemini-cli >/dev/null 2>&1
      ;;
    *)
      command -v "$1" >/dev/null 2>&1
      ;;
  esac
}

run_tool_update() {
  case "$1" in
    herdr)        herdr update ;;
    pi)           pi update --all ;;
    omp)          omp update && omp update --plugins ;;
    claude)       claude update && claude plugin marketplace update ;;
    codex)        update_codex ;;
    grok)         grok update ;;
    amp)          amp update ;;
    cursor-agent) cursor-agent update ;;
    gemini)       update_gemini ;;
    *)
      echo "${RED}Unknown tool: $1${RESET}" >&2
      return 1
      ;;
  esac
}

update_one() {
  local tool="$1"

  if ! tool_installed "$tool"; then
    echo "${YELLOW}⊘ $tool is not installed, skipping${RESET}"
    SKIPPED="$SKIPPED $tool"
    return 0
  fi

  echo
  echo "${BLUE}==> Updating $tool${RESET}"
  if run_tool_update "$tool"; then
    UPDATED="$UPDATED $tool"
  else
    echo "${RED}✘ $tool failed to update${RESET}" >&2
    FAILED="$FAILED $tool"
  fi
}

list_tools() {
  local tool
  for tool in $ALL_TOOLS; do
    if tool_installed "$tool"; then
      echo "${GREEN}✔${RESET} $tool"
    else
      echo "${YELLOW}⊘${RESET} $tool (not installed)"
    fi
  done
}

summarize() {
  local tool
  echo
  echo "${BLUE}==> Summary${RESET}"
  for tool in $UPDATED; do
    echo "${GREEN}✔${RESET} $tool"
  done
  for tool in $SKIPPED; do
    echo "${YELLOW}⊘${RESET} $tool (not installed)"
  done
  for tool in $FAILED; do
    echo "${RED}✘${RESET} $tool (failed)"
  done

  if [ -n "$FAILED" ]; then
    echo
    echo "${RED}Some tools failed to update:$FAILED${RESET}" >&2
    return 1
  fi
  return 0
}

main() {
  local targets="$ALL_TOOLS"
  local arg
  local requested=""

  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        return 0
        ;;
      -l|--list)
        list_tools
        return 0
        ;;
      -*)
        echo "${RED}Unknown option: $arg${RESET}" >&2
        usage >&2
        return 2
        ;;
      *)
        case " $ALL_TOOLS " in
          *" $arg "*)
            requested="$requested $arg"
            ;;
          *)
            echo "${RED}Unknown tool: $arg${RESET}" >&2
            usage >&2
            return 2
            ;;
        esac
        ;;
    esac
  done

  [ -n "$requested" ] && targets="$requested"

  echo "${BLUE}🤖 Updating AI tooling...${RESET}"

  local tool
  for tool in $targets; do
    update_one "$tool"
  done

  summarize
}

main "$@"
