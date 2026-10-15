#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE="/home/agmiar/Desktop/PFT-S3/sprint3-preview1.gns3project"
REMOTE="Google Drive:"
REMOTE_NAME="sprint3-preview1_latest.gns3project"
STATE_DIR="/home/agmiar/.local/state/pft-s3-gdrive"
LOCK_FILE="$STATE_DIR/upload.lock"
META_FILE="$STATE_DIR/uploaded.meta"
LOG_FILE="$STATE_DIR/upload.log"
CHECK_INTERVAL=900
START_HOUR=12
STABILITY_SECONDS=30

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    printf '%s\n' "Ya hay otra ejecución activa; se omite esta ejecución." >&2
    exit 0
fi

log() {
    printf '[%s] %s\n' "$(date '+%F %T %Z')" "$*" | tee -a "$LOG_FILE"
}

wait_until_start_time() {
    local now target wait_seconds
    now=$(date +%s)
    target=$(date -d "today ${START_HOUR}:00:00" +%s)

    if (( now < target )); then
        wait_seconds=$((target - now))
        log "Esperando hasta las 12:00 para comenzar la validación (${wait_seconds}s)."
        sleep "$wait_seconds"
    fi
}

portable_is_stable() {
    local size_before mtime_before size_after mtime_after

    [[ -s "$SOURCE" ]] || return 1
    size_before=$(stat -c '%s' -- "$SOURCE")
    mtime_before=$(stat -c '%Y' -- "$SOURCE")
    sleep "$STABILITY_SECONDS"
    size_after=$(stat -c '%s' -- "$SOURCE")
    mtime_after=$(stat -c '%Y' -- "$SOURCE")

    [[ "$size_before" == "$size_after" && "$mtime_before" == "$mtime_after" ]]
}

portable_has_final_zip_directory() {
    python3 - "$SOURCE" <<'PY'
import sys
import zipfile

path = sys.argv[1]
try:
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if "project.gns3" not in names:
            raise RuntimeError("falta project.gns3")
except Exception:
    raise SystemExit(1)
PY
}

wait_until_start_time

while true; do
    if [[ ! -f "$SOURCE" ]]; then
        log "Todavía no existe: $SOURCE"
    elif ! portable_is_stable; then
        log "El archivo todavía está creciendo o cambiando; se reintentará en 15 minutos."
    elif ! portable_has_final_zip_directory; then
        log "El archivo está estable, pero aún no tiene un ZIP portable finalizado; se reintentará en 15 minutos."
    else
        current_meta=$(stat -c '%s:%Y' -- "$SOURCE")

        if [[ -f "$META_FILE" && "$(<"$META_FILE")" == "$current_meta" ]]; then
            log "La versión ya fue subida anteriormente; no se duplica la carga."
            exit 0
        fi

        log "Exportación finalizada y validada. Subiendo a $REMOTE$REMOTE_NAME."
        rclone copyto "$SOURCE" "$REMOTE$REMOTE_NAME" \
            --transfers 1 \
            --retries 5 \
            --low-level-retries 20 \
            --log-file "$LOG_FILE" \
            --log-level INFO

        printf '%s\n' "$current_meta" > "$META_FILE"
        log "Carga completada: $REMOTE$REMOTE_NAME"
        exit 0
    fi

    sleep "$CHECK_INTERVAL"
done
