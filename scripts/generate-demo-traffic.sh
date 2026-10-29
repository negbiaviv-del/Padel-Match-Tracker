#!/usr/bin/env bash
# יוצר בקשות קריאה בטוחות דרך הממשק לצורך הדגמת מדדים.

set -euo pipefail

# מגדיר כמות בקשות והשהיה, עם ערכי ברירת מחדל בטוחים.
REQUEST_COUNT="${1:-30}"
DELAY_SECONDS="${2:-1}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
API_URL="${BASE_URL%/}/api/v1/matches"

# מוודא שכלי השליחה הדרוש זמין במכונה.
if ! command -v curl > /dev/null 2>&1; then
  echo "Error: curl is required but was not found." >&2
  exit 1
fi

# מוודא שכמות הבקשות היא מספר חיובי.
if ! [[ "${REQUEST_COUNT}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: request count must be a positive whole number." >&2
  exit 1
fi

# מציג את פרטי ההדגמה לפני שליחת התעבורה.
echo "Sending ${REQUEST_COUNT} safe GET requests to ${API_URL}"

# שולח בקשות קריאה בלבד דרך Nginx, בלי לשנות נתוני משחקים.
for ((request_number = 1; request_number <= REQUEST_COUNT; request_number++)); do
  curl --fail --silent --show-error --output /dev/null "${API_URL}"
  echo "Request ${request_number}/${REQUEST_COUNT} completed."

  if (( request_number < REQUEST_COUNT )); then
    sleep "${DELAY_SECONDS}"
  fi
done

# מציג הודעת סיום לאחר שכל הבקשות הצליחו.
echo "Demo traffic completed successfully."
