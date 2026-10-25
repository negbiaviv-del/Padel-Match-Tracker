# מייבא את סוגי הנתונים ואת הכלים להגדרת טבלת המשחקים.
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import CheckConstraint, DateTime, Integer, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


# מגדיר את טבלת המשחקים ואת הכללים שהיא אוכפת.
class Match(Base):
    __tablename__ = "matches"

    # מונע תוצאות שליליות ותוצאת תיקו במערכות.
    __table_args__ = (
        CheckConstraint(
            "team_a_sets >= 0",
            name="ck_matches_team_a_sets_nonnegative",
        ),
        CheckConstraint(
            "team_b_sets >= 0",
            name="ck_matches_team_b_sets_nonnegative",
        ),
        CheckConstraint(
            "team_a_sets <> team_b_sets",
            name="ck_matches_sets_not_tied",
        ),
    )

    # שומר מזהה ייחודי שנוצר עבור כל משחק.
    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    # שומר את מועד המשחק ואת מועד יצירת הרשומה.
    played_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    # שומר את ארבעת השחקנים שהשתתפו במשחק.
    team_a_player_1: Mapped[str] = mapped_column(String(100), nullable=False)
    team_a_player_2: Mapped[str] = mapped_column(String(100), nullable=False)
    team_b_player_1: Mapped[str] = mapped_column(String(100), nullable=False)
    team_b_player_2: Mapped[str] = mapped_column(String(100), nullable=False)

    # שומר את מספר המערכות שכל קבוצה ניצחה בהן.
    team_a_sets: Mapped[int] = mapped_column(Integer, nullable=False)
    team_b_sets: Mapped[int] = mapped_column(Integer, nullable=False)

    # שומר הערה אופציונלית באורך מוגבל.
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)
