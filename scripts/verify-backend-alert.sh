#!/usr/bin/env bash
# בודק שהתרעת נפילת צד השרת נדלקת ומחזיר את השירות לפעולה.

set -Eeuo pipefail

# מתמקם בשורש הפרויקט גם אם הסקריפט הופעל מתיקייה אחרת.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

# מגדיר כתובות וערכי זמן עבור בדיקת ההתרעה.
PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8000}"
ALERT_NAME="PadelBackendDown"
POLL_INTERVAL_SECONDS=10
MAX_ATTEMPTS=20

# מוודא שכלי שליחת הבקשות זמין במכונה.
if ! command -v curl > /dev/null 2>&1; then
  echo "Error: curl is required but was not found." >&2
  exit 1
fi

# מוודא שה־backend פועל לפני תחילת הבדיקה המבוקרת.
if [[ -z "$(docker compose ps -q backend)" ]]; then
  echo "Error: backend must be running before this verification starts." >&2
  exit 1
fi

# מחזיר את צד השרת לפעולה גם אם הבדיקה נכשלת או נעצרת.
restore_backend() {
  original_exit_code=$?
  trap - EXIT
  set +e

  echo "Restoring the backend..."
  docker compose start backend > /dev/null

  for attempt in $(seq 1 20); do
    if curl -fsS "${BACKEND_URL}/health/ready" > /dev/null; then
      echo "Backend is ready again."
      exit "${original_exit_code}"
    fi

    sleep 1
  done

  echo "Warning: backend was started but readiness was not confirmed." >&2
  exit "${original_exit_code}"
}

# מבטיח שה־backend יוחזר לפעולה עם סיום הסקריפט.
trap restore_backend EXIT

# מוודא ש־Prometheus מוכן לקבל שאילתות לפני תחילת הבדיקה.
curl -fsS "${PROMETHEUS_URL}/-/ready" > /dev/null

# עוצר זמנית את צד השרת כדי לדמות תקלה אמיתית.
echo "Stopping the local backend temporarily..."
docker compose stop backend

# בודק שוב ושוב אם ההתרעה עברה למצב firing.
for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  response="$(
    curl -fsS -G "${PROMETHEUS_URL}/api/v1/query" \
      --data-urlencode \
      'query=ALERTS{alertname="PadelBackendDown",alertstate="firing"}'
  )"

  firing_count="$(
    printf '%s' "${response}" \
      | python3 -c 'import json, sys; print(len(json.load(sys.stdin)["data"]["result"]))'
  )"

  if [[ "${firing_count}" -gt 0 ]]; then
    echo "Success: ${ALERT_NAME} is firing."
    exit 0
  fi

  echo "Attempt ${attempt}/${MAX_ATTEMPTS}: alert has not fired yet."
  sleep "${POLL_INTERVAL_SECONDS}"
done

echo "Error: ${ALERT_NAME} did not fire within the expected time." >&2
exit 1
