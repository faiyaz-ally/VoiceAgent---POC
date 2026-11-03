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

The worker immediately fetches up to 100 open issues from `faiyaz-ally/VoiceAgent---POC`, then checks again 30 seconds after each fetch finishes, including while waiting for your answer. Undecided issues are queued in memory and presented one at a time. Issues with a saved decision are skipped. Press **Ctrl+C** to stop. It runs only while the foreground process is active and your Mac is awake and connected.

For each issue, it displays the number, title, description, and this fixed proposed action: **Prepare a Codex task from this issue for later review.** Type `approve` (or `a`) or `reject` (or `r`), then Enter. Other answers leave the issue pending. Polling continues silently while the current prompt waits for your answer. Closing terminal input stops the worker without deciding pending issues.

Both decisions are previews only. Approval prints a confirmation; rejection prints a rejection message. Neither prepares a task, invokes Codex, executes issue instructions, or changes GitHub. Decisions are saved by issue number in `.worker-state/decisions.tsv` beside the script, excluded from Git, and remembered across checks and restarts. A decision must be saved successfully before it is confirmed.

To fetch once, review each returned issue, and exit:

```sh
bash worker.sh --once
```

Each issue is displayed as a JSON object containing its `number`, `title`, and `body` (description), followed by the proposed action and approval prompt. JSON keeps control characters escaped rather than interpreting issue content as terminal instructions. Example issue data:

```json
{"number":1,"title":"Example task","body":"Describe the requested work here."}
```

Polls do not redisplay already discovered issue details or prompts. Pending issue numbers and their original snapshots are remembered in memory: edits or reopening an already discovered issue do not queue it again. Restarting presents undecided issues again; approved and rejected issues remain skipped, including after edits or reopening. Closed issues, pull requests, and issues beyond the 100-issue limit are excluded. If authentication, permissions, networking, or an API request fails, the worker reports the GitHub CLI error and exits; restart it after resolving the problem.

## Read-only scope

The worker calls only `gh issue list`. It treats issue contents as data, invokes no Codex session, executes no tasks or repository scripts, and makes no GitHub changes. It writes only local decision records. Its approval prompt is a display-only prototype with no execution mechanism. GitHub CLI authentication is a separate setup step that stores credentials using its normal authentication mechanism.
