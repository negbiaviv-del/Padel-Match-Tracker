# מגדיר את מסד הנתונים המבודד ואת הכלים להכנת הבדיקות.
import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text


# מכריח את הבדיקות להשתמש במסד הנתונים המיועד להן בלבד.
TEST_DATABASE_NAME = "padel_match_tracker_test"
os.environ["POSTGRES_DB"] = TEST_DATABASE_NAME


# מייבא את השירות ואת החיבור רק לאחר בחירת מסד הבדיקות.
from src.database import engine
from src.main import app


# עוצר את הבדיקות אם החיבור אינו מצביע למסד הנתונים המבודד.
if engine.url.database != TEST_DATABASE_NAME:
    raise RuntimeError("Tests must use padel_match_tracker_test")


# מנקה את טבלת המשחקים לפני ואחרי כל בדיקה.
@pytest.fixture(autouse=True)
def clean_test_database() -> Generator[None, None, None]:
    with engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE matches"))

    yield

    with engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE matches"))


# מספק לקובצי הבדיקה לקוח פנימי שפונה ישירות לשירות.
@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    with TestClient(app) as test_client:
        yield test_client
