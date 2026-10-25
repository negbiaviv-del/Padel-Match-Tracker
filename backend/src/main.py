# מייבא את הכלים הדרושים להפעלת השירות, למסד הנתונים ולמבני המידע.
from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .database import check_database_connection, get_db
from .models import Match
from .schemas import MatchCreate, MatchRead


# יוצר את השירות הראשי ונותן לו שם וגרסה.
app = FastAPI(
    title="Padel Match Tracker API",
    version="0.1.0",
)


# ממיר רשומה ממסד הנתונים לתשובה בטוחה עבור הלקוח.
def to_match_read(match: Match) -> MatchRead:
    winner = (
        "team_a"
        if match.team_a_sets > match.team_b_sets
        else "team_b"
    )

    return MatchRead(
        id=match.id,
        played_at=match.played_at,
        team_a=[match.team_a_player_1, match.team_a_player_2],
        team_b=[match.team_b_player_1, match.team_b_player_2],
        team_a_sets=match.team_a_sets,
        team_b_sets=match.team_b_sets,
        winner=winner,
        notes=match.notes,
        created_at=match.created_at,
    )


# בודק שהשירות עצמו פעיל, בלי תלות במסד הנתונים.
@app.get("/health/live")
def liveness() -> dict[str, str]:
    return {"status": "ok"}


# בודק שהשירות מסוגל להתחבר למסד הנתונים.
@app.get("/health/ready")
def readiness() -> dict[str, str]:
    try:
        check_database_connection()
    except SQLAlchemyError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="database unavailable",
        ) from error

    return {"status": "ok"}


# יוצר משחק חדש ושומר אותו במסד הנתונים.
@app.post(
    "/api/v1/matches",
    response_model=MatchRead,
    status_code=status.HTTP_201_CREATED,
)
def create_match(
    payload: MatchCreate,
    db: Session = Depends(get_db),
) -> MatchRead:
    # ממיר את מבנה הבקשה למבנה השמירה של מסד הנתונים.
    match = Match(
        played_at=payload.played_at,
        team_a_player_1=payload.team_a[0],
        team_a_player_2=payload.team_a[1],
        team_b_player_1=payload.team_b[0],
        team_b_player_2=payload.team_b[1],
        team_a_sets=payload.team_a_sets,
        team_b_sets=payload.team_b_sets,
        notes=payload.notes,
    )

    # שומר את המשחק ומחזיר את הערכים שנוצרו במסד הנתונים.
    try:
        db.add(match)
        db.commit()
        db.refresh(match)
    except SQLAlchemyError as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="unable to create match",
        ) from error

    return to_match_read(match)

# מחזיר את היסטוריית המשחקים מהחדש לישן.
@app.get(
    "/api/v1/matches",
    response_model=list[MatchRead],
)
def list_matches(
    db: Session = Depends(get_db),
) -> list[MatchRead]:
    # קורא את המשחקים לפי זמן המשחק מהחדש לישן.
    try:
        matches = db.scalars(
            select(Match).order_by(Match.played_at.desc())
        ).all()
    except SQLAlchemyError as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="unable to list matches",
        ) from error

    # ממיר את רשומות מסד הנתונים לתשובה בטוחה עבור הלקוח.
    return [to_match_read(match) for match in matches]
