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

while true; do
  printf '\nOpen issues: faiyaz-ally/VoiceAgent---POC\n'
  GH_PROMPT_DISABLED=1 gh issue list \
    --repo github.com/faiyaz-ally/VoiceAgent---POC \
    --state open \
    --limit 100 \
    --json number,title,body

  if [ "${1:-}" = --once ]; then
    break
  fi
  sleep 30
done
