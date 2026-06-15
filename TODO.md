# TODO — deferred scope and known limitations

## Deferred slices (from the spec)

- **Allowlist modes polish / ergonomics** (spec slice 4) — better error messages
  for unknown hosts, possibly a `box allowlist add` helper, and per-project
  default-mode override.
- **Agent-name aliasing** (spec slice 5) — alias the run flow under the agent's
  own binary name (e.g. via `msb install`), so `claude` (or any agent) starts its
  own box directly. (Distinct from `box install`, already shipped, which symlinks
  the `box` command itself onto PATH.)
- **Snapshot-based provisioning optimization** — provision once, snapshot, boot
  subsequent runs from the snapshot instead of re-running `mise install`. Named
  volumes already carry the state; snapshots would reduce cold-start time.
- **macOS (Apple Silicon) validation** — `box` is written to be portable, but
  has only been exercised on Linux/KVM. Needs a real Apple Silicon host run.
- **Docker-in-microVM** — DONE and live-validated (`box --docker`): systemd via
  `--init auto` autostarts `docker.service`, overlay2 on a disk-backed
  `/var/lib/docker`, cpu/memory bump, dockerd readiness wait, `allowlist.dind`
  merge; sample `Dockerfile.box.docker`. `docker run hello-world` and `docker
  build` confirmed, and nested pulls are bound by the egress allowlist. See
  docs/superpowers/E2E-docker.md. Remaining: macOS validation; the docker image
  is large so first build/boot is slow.
- **CI** — no CI yet in this repo (lint + `bash tests/run.sh`; live `msb` checks
  need a KVM runner). Add a workflow once the layout settles.

## Known limitations

- **Agent runs as root inside the guest.** `msb exec` runs as root; this is
  necessary because the `/workspace` bind mount is owned by guest-root (the
  host user maps to guest-root inside the VM), and a non-root guest user cannot
  write to it. The microVM itself is the isolation boundary, but in-guest root
  is a hardening gap to revisit — ideally the guest user would be unprivileged
  once microsandbox supports a configurable UID mapping.

- **No baked base toolset.** `box provision` runs `mise install` against the
  project's `mise.toml` only; there is no global baked-tools list (the docker/
  base images add system packages like socat, but not language tools). If a
  common toolset is wanted in every sandbox, add a global mise config at provision
  time or bake tools into `Dockerfile.box.base`.

- **Cosmetic mise version-check warnings.** On every `mise` invocation the
  guest emits ~3 `mise WARN HTTP GET https://mise.en.dev/VERSION ... failed`
  lines on stderr. This is mise's self-update check hitting a host that is
  correctly not on the allowlist. Tool resolution and exit codes are unaffected.
  `MISE_VERSION_CHECK`, `MISE_NO_VERSION_CHECK`, and `MISE_CHECK_FOR_UPDATES`
  were all tried and did not suppress it on mise 2026.6.10. Revisit if the
  noise becomes a problem.

- **Provisioned marker can go stale.** The host-side marker file
  (`~/.local/state/box/<name>.provisioned`) records that provision has run.
  If the `box-mise` or `box-home` named volumes are removed outside `box reset`
  (e.g. via `msb volume rm` directly), the marker stays behind and `box` skips
  re-provisioning, leaving an empty volume. Run `box reset` then `box provision`
  to recover, or delete the marker manually.

- **Validated on Linux nested-KVM with msb 0.5.7 only.** microsandbox is beta;
  CLI syntax or behaviour may change in future releases. All `msb` invocations
  are in `lib/msb.sh` to contain the blast radius.
- `--net` is only honored before a subcommand; `box shell --net full` silently falls back to the default `sanctioned` mode (flags-first contract; a guard should reject misplaced flags).
