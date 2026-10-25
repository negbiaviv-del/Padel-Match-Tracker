# טוען את הערכים הפרטיים ואת הכלים הדרושים להרכבת החיבור.
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import URL


# מאתר את שורש הפרויקט וטוען את ההגדרות המקומיות כאשר הקובץ קיים.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


# מוודא שערך הכרחי קיים לפני שמתחילים את השירות.
def required_setting(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"{name} must be configured")

    return value


# מרכיב כתובת חיבור בטוחה ממידע סביבתי במקום לשמור סיסמה בקוד.
DATABASE_URL = URL.create(
    drivername="postgresql+psycopg",
    username=os.getenv("POSTGRES_USER", "padel_app"),
    password=required_setting("POSTGRES_PASSWORD"),
    host=os.getenv("POSTGRES_HOST", "127.0.0.1"),
    port=int(os.getenv("POSTGRES_PORT", "5432")),
    database=os.getenv("POSTGRES_DB", "padel_match_tracker"),
)
