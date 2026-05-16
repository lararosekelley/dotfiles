#!/usr/bin/env bash
set -euo pipefail

if command -v systemd-inhibit >/dev/null 2>&1 && [ "${BACKUP_INHIBITED:-0}" != "1" ]; then
  exec env BACKUP_INHIBITED=1 systemd-inhibit \
    --what=sleep \
    --why="restic backup" \
    "$0" "$@"
fi

BACKUP_MOUNT="/run/media/lara/Backups 8TB"
LOG_DIR="/home/lara/.local/state"
LOG_FILE="$LOG_DIR/backup.log"
RATE_FILE="$LOG_DIR/backup-rate-bytes-per-second"
MAX_LOG_SIZE_BYTES=$((20 * 1024 * 1024))
KEEP_LOG_FILES=5
PROGRESS_INTERVAL_SECONDS=60

export RESTIC_REPOSITORY="$BACKUP_MOUNT/restic-repo"
export RESTIC_PASSWORD_FILE="/home/lara/.config/restic/password"
EXCLUDE_FILE="/home/lara/.config/restic/excludes.txt"

SRC1="/home/lara"
SRC2="/run/media/lara/Storage"
ACTION="run"
DRY_RUN=0
ARG_ERROR=0

for arg in "$@"; do
  case "$arg" in
    run|check|prune)
      ACTION="$arg"
      ;;
    --dry-run|-n)
      DRY_RUN=1
      ;;
    -h|--help|help)
      ACTION="help"
      ;;
    *)
      echo "Unknown argument: $arg"
      ARG_ERROR=1
      ACTION="help"
      ;;
  esac
done

usage() {
  cat <<'EOF'
Usage: backup.sh [run|check|prune] [--dry-run]

  run   Perform backup, retention prune, and repository check (default)
  check Run repository check only
  prune Run repository prune only

Options:
  --dry-run, -n  For run mode: print estimate only and exit
EOF
}

format_duration() {
  local total_seconds=$1
  local hours=$((total_seconds / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  local seconds=$((total_seconds % 60))
  printf '%02d:%02d:%02d' "$hours" "$minutes" "$seconds"
}

show_preflight_estimate() {
  local total_bytes
  total_bytes=$(du -sb "$SRC1" "$SRC2" 2>/dev/null | awk '{sum += $1} END {print sum + 0}')

  if [ "$total_bytes" -le 0 ]; then
    echo "Could not estimate source size before backup."
    return
  fi

  local total_human
  total_human=$(numfmt --to=iec --suffix=B "$total_bytes")
  echo "Estimated source size upper bound: $total_human"

  if [ -f "$RATE_FILE" ]; then
    local last_rate
    last_rate=$(cat "$RATE_FILE" 2>/dev/null || printf '0')
    if [[ "$last_rate" =~ ^[0-9]+$ ]] && [ "$last_rate" -gt 0 ]; then
      local eta_seconds=$((total_bytes / last_rate))
      local rate_human
      rate_human=$(numfmt --to=iec --suffix=B "$last_rate")
      echo "Rough duration estimate from last run speed ($rate_human/s): $(format_duration "$eta_seconds")"
      echo "Estimate is intentionally conservative; incremental backups are usually much faster."
    fi
  fi
}

run_backup_with_progress() {
  local summary_file
  summary_file=$(mktemp)

  if command -v python3 >/dev/null 2>&1; then
    restic backup "$SRC1" "$SRC2" \
      --exclude-caches \
      --exclude-file "$EXCLUDE_FILE" \
      --one-file-system \
      --json | python3 -u - "$PROGRESS_INTERVAL_SECONDS" "$summary_file" <<'PY'
import json
import sys
import time


def human_bytes(value):
    if value is None:
        return "?"
    value = float(value)
    units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    idx = 0
    while value >= 1024 and idx < len(units) - 1:
        value /= 1024.0
        idx += 1
    return f"{value:.1f} {units[idx]}"


def human_duration(seconds):
    if seconds is None:
        return "?"
    seconds = int(seconds)
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


interval = int(sys.argv[1])
summary_path = sys.argv[2]
last_emit = 0.0
last_status = None
summary = None

for raw_line in sys.stdin:
    line = raw_line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except json.JSONDecodeError:
        print(line, flush=True)
        continue

    msg_type = obj.get("message_type")
    now = time.time()

    if msg_type == "status":
        last_status = obj
        if now - last_emit >= interval:
            percent = obj.get("percent_done")
            done_files = obj.get("files_done")
            total_files = obj.get("total_files")
            done_bytes = obj.get("bytes_done")
            total_bytes = obj.get("total_bytes")
            elapsed = obj.get("seconds_elapsed")
            remaining = obj.get("seconds_remaining")

            parts = ["[progress]"]
            if isinstance(percent, (int, float)):
                parts.append(f"{percent * 100:.1f}%")
            if isinstance(done_files, int) and isinstance(total_files, int) and total_files > 0:
                parts.append(f"files {done_files}/{total_files}")
            if isinstance(done_bytes, (int, float)) and isinstance(total_bytes, (int, float)) and total_bytes > 0:
                parts.append(f"bytes {human_bytes(done_bytes)}/{human_bytes(total_bytes)}")
            elif isinstance(done_bytes, (int, float)):
                parts.append(f"bytes {human_bytes(done_bytes)}")
            parts.append(f"elapsed {human_duration(elapsed)}")
            if isinstance(remaining, (int, float)) and remaining >= 0:
                parts.append(f"eta {human_duration(remaining)}")

            print(" | ".join(parts), flush=True)
            last_emit = now

    elif msg_type == "summary":
        summary = obj
        files_processed = obj.get("total_files_processed")
        bytes_processed = obj.get("total_bytes_processed")
        duration = obj.get("total_duration")
        files_new = obj.get("files_new")
        files_changed = obj.get("files_changed")
        files_unmodified = obj.get("files_unmodified")

        parts = ["[summary]"]
        if isinstance(files_processed, int):
            parts.append(f"files processed {files_processed}")
        if isinstance(bytes_processed, (int, float)):
            parts.append(f"bytes processed {human_bytes(bytes_processed)}")
        if isinstance(duration, (int, float)):
            parts.append(f"duration {human_duration(duration)}")
        if isinstance(files_new, int) and isinstance(files_changed, int) and isinstance(files_unmodified, int):
            parts.append(f"new/changed/unmodified {files_new}/{files_changed}/{files_unmodified}")
        print(" | ".join(parts), flush=True)

    elif msg_type in {"error", "verbose_error"}:
        print(f"[restic-error] {obj.get('error', line)}", flush=True)

if summary is not None:
    bytes_processed = int(summary.get("total_bytes_processed") or 0)
    duration = int(summary.get("total_duration") or 0)
    with open(summary_path, "w", encoding="utf-8") as fh:
        fh.write(f"{bytes_processed} {duration}\n")
elif last_status is not None:
    bytes_done = int(last_status.get("bytes_done") or 0)
    elapsed = int(last_status.get("seconds_elapsed") or 0)
    with open(summary_path, "w", encoding="utf-8") as fh:
        fh.write(f"{bytes_done} {elapsed}\n")
PY
  else
    restic backup "$SRC1" "$SRC2" \
      --exclude-caches \
      --exclude-file "$EXCLUDE_FILE" \
      --one-file-system
  fi

  if [ -s "$summary_file" ]; then
    local processed_bytes
    local duration_seconds
    read -r processed_bytes duration_seconds < "$summary_file"
    if [[ "$processed_bytes" =~ ^[0-9]+$ ]] && [[ "$duration_seconds" =~ ^[0-9]+$ ]] && [ "$duration_seconds" -gt 0 ]; then
      printf '%s\n' "$((processed_bytes / duration_seconds))" > "$RATE_FILE"
    fi
  fi

  rm -f "$summary_file"
}

rotate_logs() {
  if [ ! -f "$LOG_FILE" ]; then
    return
  fi

  local size
  size=$(stat -c%s "$LOG_FILE" 2>/dev/null || printf '0')
  if [ "$size" -lt "$MAX_LOG_SIZE_BYTES" ]; then
    return
  fi

  local i
  for ((i=KEEP_LOG_FILES; i>=1; i--)); do
    if [ -f "$LOG_FILE.$i" ]; then
      if [ "$i" -eq "$KEEP_LOG_FILES" ]; then
        rm -f "$LOG_FILE.$i"
      else
        mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
      fi
    fi
  done

  mv "$LOG_FILE" "$LOG_FILE.1"
}

mkdir -p "$LOG_DIR"
rotate_logs
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== $(date '+%Y-%m-%d %H:%M:%S') backup start (action=$ACTION, dry_run=$DRY_RUN) ===="

log_end() {
  local status=$?
  printf '==== %s backup end (status=%s) ====\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$status"
}

trap log_end EXIT

case "$ACTION" in
  run|check|prune)
    ;;
  help)
    usage
    if [ "$ARG_ERROR" -eq 1 ]; then
      exit 1
    fi
    exit 0
    ;;
  *)
    echo "Unknown action: $ACTION"
    usage
    exit 1
    ;;
esac

if [ "$ACTION" != "run" ] && [ "$DRY_RUN" -eq 1 ]; then
  echo "--dry-run is only supported with run mode"
  exit 1
fi

if [ "$ACTION" = "run" ] && [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run mode: estimate only; no backup operations will be performed."
  show_preflight_estimate
  exit 0
fi

if ! command -v restic >/dev/null 2>&1; then
  echo "restic is not installed. Install it with: sudo dnf install restic"
  exit 1
fi

if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
  echo "Password file not found: $RESTIC_PASSWORD_FILE"
  exit 1
fi

if [ "$ACTION" = "run" ] && [ ! -f "$EXCLUDE_FILE" ]; then
  echo "Exclude file not found: $EXCLUDE_FILE"
  exit 1
fi

if ! mountpoint -q "$BACKUP_MOUNT"; then
  echo "Backup drive not mounted: $BACKUP_MOUNT"
  exit 1
fi

if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
  echo "No restic repo found, initializing: $RESTIC_REPOSITORY"
  mkdir -p "$RESTIC_REPOSITORY"
  restic init
fi

if [ "$ACTION" = "check" ]; then
  echo "Running restic repository check only."
  restic check
  exit 0
fi

if [ "$ACTION" = "prune" ]; then
  echo "Running restic repository prune only."
  restic prune
  exit 0
fi

show_preflight_estimate
echo "Progress updates will be printed roughly every ${PROGRESS_INTERVAL_SECONDS}s."
run_backup_with_progress

restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --prune

restic check
