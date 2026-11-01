#!/usr/bin/env bash

# עוצר את הסקריפט במקרה של שגיאה, משתנה חסר או כשל בצינור פקודות.
set -euo pipefail

# מחשב את נתיבי הפרויקט, שכבת האתחול וסביבת הפיתוח.
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="${PROJECT_ROOT}/terraform/bootstrap/state"
ENVIRONMENT_DIR="${PROJECT_ROOT}/terraform/environments/dev"

# בודק שפקודת Terraform זמינה במכונה.
if ! command -v terraform > /dev/null 2>&1; then
  echo "Error: Terraform is not installed or is not available in PATH." >&2
  exit 1
fi

# בודק ששכבת האתחול כבר יצרה מאגר מצב תקין.
if ! terraform -chdir="${BOOTSTRAP_DIR}" output -raw state_bucket_name > /dev/null 2>&1; then
  echo "Error: Terraform state bucket was not found in the bootstrap state." >&2
  echo "Run the bootstrap Terraform workflow before initializing the development environment." >&2
  exit 1
fi

# קורא את שם המאגר ואת האזור מתוך שכבת האתחול.
STATE_BUCKET="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw state_bucket_name)"
STATE_REGION="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw state_bucket_region)"

# מאתחל את סביבת הפיתוח עם מצב מרוחק ונעילה אוטומטית.
terraform -chdir="${ENVIRONMENT_DIR}" init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=environments/dev/terraform.tfstate" \
  -backend-config="region=${STATE_REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

# בודק שתצורת סביבת הפיתוח תקינה לאחר החיבור למאגר.
terraform -chdir="${ENVIRONMENT_DIR}" validate

# מציג את פרטי החיבור שאותחלו בהצלחה.
echo "Remote Terraform backend initialized successfully."
echo "State bucket: ${STATE_BUCKET}"
echo "State key: environments/dev/terraform.tfstate"
