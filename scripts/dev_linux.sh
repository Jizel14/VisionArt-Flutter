#!/usr/bin/env bash
set -euo pipefail
# Run VisionArt Flutter on Linux with API URL set automatically.
# Prefers 192.168.*, then 10.*, else 127.0.0.1 (same PC as Nest).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pick_ip() {
  local ip
  ip=$(ip -4 -brief addr show 2>/dev/null | awk '$2=="UP" && $3 ~ /^192\.168\./ {split($3,a,"/"); print a[1]; exit}')
  if [[ -n "$ip" ]]; then echo "$ip"; return; fi
  ip=$(ip -4 -brief addr show 2>/dev/null | awk '$2=="UP" && $3 ~ /^10\./ {split($3,a,"/"); print a[1]; exit}')
  if [[ -n "$ip" ]]; then echo "$ip"; return; fi
  echo "127.0.0.1"
}

HOST="$(pick_ip)"
if [[ "${USE_LOCALHOST:-}" == "1" ]]; then HOST="127.0.0.1"; fi

if grep -q '^API_BASE_URL=' .env 2>/dev/null; then
  sed -i "s|^API_BASE_URL=.*|API_BASE_URL=http://${HOST}:3000|" .env
else
  printf '\nAPI_BASE_URL=http://%s:3000\n' "$HOST" >> .env
fi

echo "API_BASE_URL=http://${HOST}:3000 (set in .env)"

if ! curl -sS -o /dev/null --connect-timeout 2 "http://127.0.0.1:3000/auth/me"; then
  echo "Nest not responding on :3000 — start it from repo: cd ../../backend && npm run start:dev" >&2
  exit 1
fi

flutter pub get
exec flutter run -d linux --no-pub
