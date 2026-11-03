# VoiceAgent---POC

A minimal read-only GitHub issues worker for macOS, based on [worker-plan.md](worker-plan.md).

## Setup

Install [GitHub CLI](https://cli.github.com/) with Homebrew if needed:

```sh
brew install gh
```

Authenticate with GitHub if you have not already:

```sh
gh auth login --hostname github.com
```

The worker uses GitHub CLI's existing authentication. For credentials that enforce read-only access, use a dedicated fine-grained token restricted to this repository with Issues: read-only and the required Metadata: read-only permission. Supply it through `GH_TOKEN` using your credential manager; do not put tokens in source files or commit them.

## Run

From the cloned repository:

```sh
cd ~/VoiceAgent---POC
bash worker.sh
```

The worker immediately fetches up to 100 open issues from `faiyaz-ally/VoiceAgent---POC`, then checks again 30 seconds after each fetch finishes. It prints each newly discovered issue once per run. Issues present on the first fetch are considered newly discovered. Press **Ctrl+C** to stop. It runs only while the foreground process is active and your Mac is awake and connected.

To fetch once and exit:

```sh
bash worker.sh --once
```

Output is one JSON object per newly discovered issue, containing its `number`, `title`, and `body` (description). JSON keeps control characters escaped rather than interpreting issue content as terminal instructions. For example:

```json
{"number":1,"title":"Example task","body":"Describe the requested work here."}
```

Polls with no newly discovered issues produce no output. Issue numbers are remembered only in memory: edits or reopening an already displayed issue do not print it again, but restarting the worker resets the memory. Closed issues, pull requests, and issues beyond the 100-issue limit are excluded. If authentication, permissions, networking, or an API request fails, the worker reports the GitHub CLI error and exits; restart it after resolving the problem.

## Read-only scope

The worker calls only `gh issue list`. It treats issue contents as data, invokes no Codex session, executes no tasks or repository scripts, writes no application files, and makes no GitHub changes. It has no approval or task execution mechanism. GitHub CLI authentication is a separate setup step that stores credentials using its normal authentication mechanism.
