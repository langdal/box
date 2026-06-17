#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$ROOT/tests/lib/harness.sh"
source "$ROOT/lib/msb.sh"

export BOX_DRY_RUN=1

# _msb prints instead of executing under dry-run.
assert_eq "msb ps" "$(_msb ps)" "_msb prints under dry-run"

# is_running is always false under dry-run (no daemon contacted).
if msb_is_running anything; then
  assert_eq "running" "not-running" "is_running must be false in dry-run"
else
  assert_eq "ok" "ok" "is_running false in dry-run"
fi

# msb_up builds a detached `run -d --replace --name` command with mounts, net, image, NO trailing cmd.
# --replace ensures a fresh boot (new allowlist/secrets) when a stopped sandbox of the same name exists.
out="$(msb_up box-proj mcr.microsoft.com/devcontainers/base:ubuntu /tmp/p sanctioned github.com)"
assert_contains "$out" "msb run -d --replace --name box-proj" "detached named run"
assert_contains "$out" "--mount-dir /tmp/p:/workspace" "mounts workspace"
assert_contains "$out" "--mount-named box-mise:/mise" "mounts mise volume"
assert_contains "$out" "--net-default-egress deny" "locked egress"
assert_contains "$out" "--rlimit nofile=65536" "run raises the guest open-file limit"
# image is the LAST token, with no trailing `-- cmd`
assert_eq "mcr.microsoft.com/devcontainers/base:ubuntu" "${out##* }" "image is last token"

# msb_up with no hosts still works (sanctioned, deny only).
out_nohost="$(msb_up box-proj img /tmp/p sanctioned)"
assert_contains "$out_nohost" "msb run -d --replace --name box-proj" "detached run with no hosts"

# attach uses exec against the named sandbox.
# attach uses exec against the named sandbox, with the mise env injected.
attach_out="$(msb_attach box-proj -- echo hi)"
assert_contains "$attach_out" "msb exec" "attach via exec"
assert_contains "$attach_out" "--env PATH=/mise/shims:/mise/bin:" "attach injects mise PATH"
assert_contains "$attach_out" "--env HOME=/home/vscode" "attach points HOME at the persistent home volume"
assert_contains "$attach_out" "--env TMPDIR=/workspace/.tmp" "attach points TMPDIR at host-backed workspace scratch"
assert_contains "$attach_out" "--workdir /workspace" "attach lands in the workspace"

# TMPDIR is overridable via BOX_TMPDIR (e.g. back to the default tmpfs).
# Re-source so the BOX_TMPDIR override is read at definition time.
tmp_out="$(BOX_TMPDIR=/tmp bash -c 'source "'"$ROOT"'/lib/msb.sh"; BOX_DRY_RUN=1 msb_attach box-proj -- echo hi')"
assert_contains "$tmp_out" "--env TMPDIR=/tmp" "BOX_TMPDIR overrides the scratch dir"

# msb_tmp_seed creates the scratch dir in the guest (pip et al. need it to exist).
seed_out="$(msb_tmp_seed box-proj)"
assert_contains "$seed_out" "msb exec box-proj -- mkdir -p /workspace/.tmp" "tmp_seed creates the scratch dir"

# msb_sysctl_seed raises the system-wide open-file table (fs.file-max), not just
# the per-process rlimit; BOX_FILE_MAX overrides the target.
sysctl_out="$(msb_sysctl_seed box-proj)"
assert_contains "$sysctl_out" "msb exec box-proj -- sh -c" "sysctl_seed runs in the guest"
assert_contains "$sysctl_out" "fs.file-max" "sysctl_seed raises fs.file-max"
assert_contains "$sysctl_out" "f=2097152" "sysctl_seed defaults file-max to 2097152"
sysctl_override="$(BOX_FILE_MAX=314159 BOX_DRY_RUN=1 bash -c 'source "$0"; msb_sysctl_seed box-proj' "$ROOT/lib/msb.sh")"
assert_contains "$sysctl_override" "f=314159" "BOX_FILE_MAX overrides the file-max target"
assert_contains "$attach_out" "--rlimit nofile=65536" "attach raises the guest open-file limit"
assert_contains "$attach_out" "box-proj -- echo hi" "attach passes command to sandbox"

# start_run forwards secrets when provided via BOX_SECRETS env (newline list).
out2="$(BOX_SECRETS=$'GITHUB_TOKEN@api.github.com' \
        msb_up box-proj img /tmp/p sanctioned github.com)"
assert_contains "$out2" "--secret GITHUB_TOKEN@api.github.com" "msb_up forwards secrets"

# No BOX_SECRETS -> no --secret flag.
out3="$(msb_up box-proj img /tmp/p sanctioned github.com)"
assert_eq "" "$(echo "$out3" | grep -o -- '--secret' || true)" "no secrets -> no --secret flag"

finish
