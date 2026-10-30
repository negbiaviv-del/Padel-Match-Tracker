#!/usr/bin/env bash
# מקים ובודק את כל סביבת הפיתוח המקומית של הפרויקט.

set -Eeuo pipefail

# עובר לשורש הפרויקט בלי להיות תלוי בתיקייה שממנה הופעל הסקריפט.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

# מוודא שקובץ ההגדרות המקומי והסודי קיים.
if [[ ! -f ".env" ]]; then
  echo "Error: .env is missing. Copy .env.example to .env and set local passwords." >&2
  exit 1
fi

# מוודא שכלי Docker, Compose ו-curl זמינים לפני תחילת ההקמה.
for command_name in docker curl; do
  if ! command -v "${command_name}" > /dev/null 2>&1; then
    echo "Error: ${command_name} is required but was not found." >&2
    exit 1
  fi
done

if ! docker compose version > /dev/null 2>&1; then
  echo "Error: Docker Compose is required but was not found." >&2
  exit 1
fi

# בודק את הגדרת Compose בלי להציג ערכים סודיים.
docker compose config --quiet

# בונה תמונות עדכניות ומפעיל את כל שירותי הפיתוח.
docker compose up -d --build

# ממתין לשירות HTTP עד שהוא עונה בהצלחה או שמסתיים הזמן המותר.
wait_for_http() {
  local service_name="$1"
  local url="$2"
  local max_attempts="${3:-60}"

  for attempt in $(seq 1 "${max_attempts}"); do
    if curl --fail --silent --show-error "${url}" > /dev/null 2>&1; then
      echo "${service_name} is ready."
      return 0
    fi

    sleep 1
  done

  echo "Error: ${service_name} did not become ready." >&2
  docker compose ps
  return 1
}

# מוודא שכל רכיב מוכן באמת לפני שמציג את כתובות הגישה.
wait_for_http "Backend" "http://127.0.0.1:8000/health/ready"
wait_for_http "Frontend" "http://127.0.0.1:8080/"
wait_for_http "Prometheus" "http://127.0.0.1:9090/-/ready"
wait_for_http "Grafana" "http://127.0.0.1:3000/api/health"

# מציג את מצב המכולות ואת כתובות הגישה לאחר הקמה מוצלחת.
docker compose ps

echo
echo "Local Padel Match Tracker environment is ready:"
echo "  Frontend:   http://127.0.0.1:8080/"
echo "  Backend:    http://127.0.0.1:8000/docs"
echo "  Prometheus: http://127.0.0.1:9090/"
echo "  Grafana:    http://127.0.0.1:3000/"
