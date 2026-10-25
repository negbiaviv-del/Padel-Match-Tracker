# מייבא כלים להגדרת מבנה המידע ובדיקת תקינותו.
from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


# מגדיר את המידע שהלקוח רשאי לשלוח בעת יצירת משחק.
class MatchCreate(BaseModel):
    # דוחה שדות לא צפויים ומסיר רווחים מיותרים מטקסטים.
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    # מגדיר את זמן המשחק, הקבוצות, התוצאה וההערה האופציונלית.
    played_at: datetime
    team_a: list[str] = Field(min_length=2, max_length=2)
    team_b: list[str] = Field(min_length=2, max_length=2)
    team_a_sets: int = Field(ge=0)
    team_b_sets: int = Field(ge=0)
    notes: str | None = Field(default=None, max_length=500)

    # מוודא שזמן המשחק כולל אזור זמן ואינו נמצא בעתיד.
    @field_validator("played_at")
    @classmethod
    def validate_played_at(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("played_at must include a timezone")

        if value > datetime.now(timezone.utc):
            raise ValueError("played_at cannot be in the future")

        return value

    # מוודא שבכל קבוצה יש שני שמות תקינים ושונים.
    @field_validator("team_a", "team_b")
    @classmethod
    def validate_team(cls, value: list[str]) -> list[str]:
        normalized_players = [player.strip() for player in value]

        if any(not player for player in normalized_players):
            raise ValueError("player names cannot be empty")

        if len({player.casefold() for player in normalized_players}) != 2:
            raise ValueError("players in a team must be unique")

        return normalized_players

    # הופך הערה ריקה לערך חסר במקום לשמור מחרוזת ריקה.
    @field_validator("notes")
    @classmethod
    def normalize_notes(cls, value: str | None) -> str | None:
        if value is None:
            return None

        return value.strip() or None

    # מוודא שאין אותו שחקן בשתי הקבוצות ושאין תיקו.
    @model_validator(mode="after")
    def validate_match(self) -> MatchCreate:
        all_players = [*self.team_a, *self.team_b]

        if len({player.casefold() for player in all_players}) != 4:
            raise ValueError("a player cannot appear more than once")

        if self.team_a_sets == self.team_b_sets:
            raise ValueError("a match cannot end in a tie")

        return self


# מגדיר את המידע שהשירות יחזיר לאחר יצירה או קריאה של משחק.
class MatchRead(BaseModel):
    # מחזיר את פרטי המשחק ואת הערכים שהשירות חישב.
    id: UUID
    played_at: datetime
    team_a: list[str]
    team_b: list[str]
    team_a_sets: int
    team_b_sets: int
    winner: Literal["team_a", "team_b"]
    notes: str | None
    created_at: datetime
