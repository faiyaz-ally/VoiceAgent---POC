#!/bin/bash
set -eu

case "${1:-}" in
  ""|--once) ;;
  *) printf 'Usage: bash worker.sh [--once]\n' >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  printf 'Usage: bash worker.sh [--once]\n' >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  printf 'GitHub CLI is required. Install it with: brew install gh\n' >&2
  exit 1
fi

# Keep terminal input separate from the issue-data read loop below.
exec 3<&0
state_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/.worker-state"
decisions_file="$state_dir/decisions.tsv"
seen='|'
if [ -f "$decisions_file" ]; then
  while IFS=$'\t' read -r number decision; do
    case "$number" in
      ''|*[!0-9]*) continue ;;
    esac
    case "$decision" in
      approve|reject) seen="${seen}${number}|" ;;
    esac
  done < "$decisions_file"
fi
queue=()
queue_numbers=()
discovered=0
reviewed=0
shown=-1
next_poll=0
fetched=false

fetch_issues() {
  issues=$(GH_PROMPT_DISABLED=1 gh issue list \
    --repo github.com/faiyaz-ally/VoiceAgent---POC \
    --state open \
    --limit 100 \
    --json number,title,body \
    --jq '.[] | "\(.number)\t\(tojson)"')

  if [ -n "$issues" ]; then
    while IFS=$'\t' read -r number issue; do
      case "$seen" in
        *"|$number|"*) continue ;;
      esac
      queue[$discovered]="$issue"
      queue_numbers[$discovered]="$number"
      discovered=$((discovered + 1))
      seen="${seen}${number}|"
    done <<< "$issues"
  fi

  fetched=true
  next_poll=$((SECONDS + 30))
}

record_decision() {
  mkdir -p "$state_dir"
  printf '%s\t%s\n' "${queue_numbers[$reviewed]}" "$1" >> "$decisions_file"
}

while true; do
  if [ "$fetched" = false ] || { [ "${1:-}" != --once ] && [ "$SECONDS" -ge "$next_poll" ]; }; then
    fetch_issues
  fi

  if [ "$reviewed" -lt "$discovered" ]; then
    if [ "$shown" -ne "$reviewed" ]; then
      printf '\nIssue: %s\n' "${queue[$reviewed]}"
      printf 'Proposed action: Prepare a Codex task from this issue for later review.\n'
      printf 'Preview only: neither choice prepares a task, launches Codex, or executes issue instructions.\n'
      printf 'Approve or reject? [approve/reject]: '
      shown=$reviewed
    fi
    wait_seconds=$((next_poll - SECONDS))
    if [ "$wait_seconds" -le 0 ]; then
      wait_seconds=1
    fi
    # --once fetches only once, but still asks about every discovered issue.
    if [ "${1:-}" = --once ]; then
      if IFS= read -r -u 3 answer; then
        input_status=0
      else
        input_status=$?
      fi
    elif IFS= read -r -t "$wait_seconds" -u 3 answer; then
      input_status=0
    else
      input_status=$?
    fi

    if [ "$input_status" -eq 0 ]; then
      case "$answer" in
        approve|a|A)
          record_decision approve
          printf 'Approved (preview only). No task prepared or executed.\n'
          reviewed=$((reviewed + 1))
          ;;
        reject|r|R)
          record_decision reject
          printf 'Rejected. No task prepared or executed.\n'
          reviewed=$((reviewed + 1))
          ;;
        *) printf 'Enter approve or reject: ' ;;
      esac
    elif [ "$input_status" -gt 128 ] || { [ "${1:-}" != --once ] && [ "$SECONDS" -ge "$next_poll" ]; }; then
      # Keep the existing prompt visible while polling continues.
      # macOS Bash 3 reports timeout as 1; newer Bash versions use >128.
      :
    else
      printf '\nInput closed; stopping without deciding pending issues.\n' >&2
      exit 1
    fi
  elif [ "${1:-}" = --once ]; then
    break
  else
    wait_seconds=$((next_poll - SECONDS))
    if [ "$wait_seconds" -gt 0 ]; then
      sleep "$wait_seconds"
    fi
  fi
done
