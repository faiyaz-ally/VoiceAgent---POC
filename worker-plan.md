**Use GitHub CLI (`gh`) in a simple polling loop.** You already have it installed. This is enough to read issues and display them in Terminal.

| Option | Best use |
|---|---|
| **`gh` + shell loop** | Smallest starting point; repeatedly displays issues |
| Python script + GitHub API | Later, if you want formatting, deduplication, or only changed issues |

For a single read:

```zsh
gh issue list \
  --repo faiyaz-ally/VoiceAgent---POC \
  --state open \
  --limit 100 \
  --json number,title,body,url
```

GitHub calls the issue description `body`. These fields are supported by [`gh issue list`](https://cli.github.com/manual/gh_issue_list).

For a minimal worker that checks every 30 seconds:

```zsh
while true; do
  gh issue list \
    --repo faiyaz-ally/VoiceAgent---POC \
    --state open \
    --limit 100 \
    --json number,title,body,url
  sleep 30
done
```

Press **Ctrl+C** to stop. Each poll prints another snapshot; it displays up to 100 open issues.

The loop only fetches and prints data. Issue content is JSON, never interpreted as commands. It doesn’t invoke Codex, modify files, or write to GitHub. For enforced GitHub read-only access, give it a dedicated credential with read-only repository permissions.

I haven’t created or started a worker.
