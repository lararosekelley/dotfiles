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
MAX_LOG_SIZE_BYTES=$((20 * 1024 * 1024))
KEEP_LOG_FILES=5

export RESTIC_REPOSITORY="$BACKUP_MOUNT/restic-repo"
export RESTIC_PASSWORD_FILE="/home/lara/.config/restic/password"

SRC1="/home/lara"
SRC2="/run/media/lara/Storage"

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

echo "==== $(date '+%Y-%m-%d %H:%M:%S') backup start ===="

log_end() {
  local status=$?
  printf '==== %s backup end (status=%s) ====\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$status"
}

trap log_end EXIT

if ! command -v restic >/dev/null 2>&1; then
  echo "restic is not installed. Install it with: sudo dnf install restic"
  exit 1
fi

if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
  echo "Password file not found: $RESTIC_PASSWORD_FILE"
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

restic backup "$SRC1" "$SRC2" \
  --exclude-caches \
  --one-file-system
restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --prune

restic check
