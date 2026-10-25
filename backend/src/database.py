# מייבא את הכלים שיוצרים ומנהלים חיבורים למסד הנתונים.
from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import DATABASE_URL


# מגדיר בסיס משותף לכל מודלי הנתונים של השירות.
class Base(DeclarativeBase):
    pass


# יוצר מנהל חיבורים משותף עבור השירות.
engine: Engine = create_engine(
    DATABASE_URL,
    # בודק חיבורים ישנים לפני שימוש חוזר בהם.
    pool_pre_ping=True,
)


# יוצר מפעל שמפיק סביבת עבודה נפרדת לכל בקשה.
SessionLocal = sessionmaker(
    bind=engine,
    # שומר שליטה מפורשת על שליחת שינויים למסד הנתונים.
    autoflush=False,
    # מחייב אישור מפורש לפני שמירת שינויים.
    autocommit=False,
)


# מספק סביבת עבודה לבקשה וסוגר אותה בסיומה.
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# בודק שאפשר להתחבר למסד הנתונים ולהריץ שאילתה פשוטה.
def check_database_connection() -> None:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
