# CLAUDE.md

Guidance for Claude Code working in this repository.

## Git Rules

- Create commits when asked.
- If GPG signing fails because no key/agent is available (typical in a sandbox),
  commit without signing: `git -c commit.gpgsign=false commit ...`. The user
  re-signs later.
- **NEVER** `git push` (any variant). Leave commits local and re-ask each time.
- When finishing without committing, end with a proposed one-line
  [Conventional Commits](https://www.conventionalcommits.org/) message
  (`type(scope): subject`, imperative, ~72 chars) in a fenced bash block. This
  repo uses Conventional Commits to drive versioning.

## Project Overview

`box` runs a coding agent inside a hardware-isolated **microVM** via
[microsandbox](https://microsandbox.dev) (libkrun-based, runs standard OCI
images, ships an `msb` CLI). The operator stays unrestricted on the host; only
the agent runs in the VM. It supersedes an earlier container + iptables/tinyproxy
`dev` tool (which still lives in its own repo for Docker-based setups).

Properties: operator-on-host with the workspace bind-mounted live both ways;
mise-driven per-project tools; a static egress allowlist editable from outside
the sandbox; leak-proof secret injection; single-command DX.

## Build / Run

`box` is a single bash script (no build step). Requirements: Linux+KVM or macOS
Apple Silicon, and `msb` installed (`curl -fsSL https://install.microsandbox.dev | sh`).

```bash
./box                 # boot/attach the sandbox for $PWD, open a shell
./box -- CMD          # one-off command
./box provision       # open-egress build step (mise install into the volume)
./box --docker        # run with a Docker daemon inside (auto-builds its image)
./box --port 5173     # publish a guest port to the host
./box --host-port 11434  # let the guest reach a host service (host.docker.internal)
./box install         # symlink box onto PATH
./box self-update     # update the git checkout to the latest release tag
```

See `README.md` for the full command reference and design.

## Tests

Plain bash, no dependencies:

```bash
bash tests/run.sh                 # all unit tests
bash tests/unit/test-msb-run.sh   # one file
```

Tests use a `BOX_DRY_RUN=1` seam: every `msb` call prints `msb <args>` instead of
executing, so command construction is asserted without booting a VM.
`BOX_ASSUME_PROVISIONED=1` skips the provision check; `BOX_FAKE_RUNNING=1` makes
`msb_is_running` report true (for the restart-on-config-change path).

Lint: `mise install` then `shellcheck box lib/*.sh tests/**/*.sh`.

## Architecture (the one rule that matters)

- **`box`** — the CLI/UX: arg parsing, subcommand dispatch, allowlist merge,
  provision/boot orchestration, config-change detection. Contains **no** `msb`
  syntax.
- **`lib/msb.sh`** — the **only** file that knows microsandbox `msb` syntax.
  Every `msb` invocation lives here behind named functions. microsandbox is
  pre-1.0; confining it to one file keeps breakage contained. When `msb` changes,
  fix it here.
- `lib/allowlist.sh`, `lib/secrets.sh` — pure helpers (no `msb` syntax).
- `allowlist.default` (+ `allowlist.dind` for `--docker`) — baked egress
  allowlists; per-project `.box-allowlist` / `.box-secrets` extend them.

Key facts confirmed against microsandbox 0.5.x are in `docs/superpowers/`
(SPIKE + E2E notes) — read those before changing `lib/msb.sh`.
