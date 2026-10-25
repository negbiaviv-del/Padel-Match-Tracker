"""create matches table

Revision ID: 044fa92c5947
Revises:
Create Date: 2026-10-25 20:16:42.024906

"""

# מייבא את סוגי הנתונים ואת הכלים להפעלת שינויי מסד הנתונים.
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# מגדיר את מזהי המיגרציה ואת מקומה בהיסטוריית השינויים.
revision: str = "044fa92c5947"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# יוצר את טבלת המשחקים ואת כל כללי התקינות שלה.
def upgrade() -> None:
    # יוצר את הטבלה עם העמודות הדרושות לשמירת משחק.
    op.create_table(
        "matches",
        # שומר מזהה ייחודי עבור כל משחק.
        sa.Column("id", sa.Uuid(), nullable=False),

        # שומר את זמן המשחק ואת זמן יצירת הרשומה.
        sa.Column("played_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),

        # שומר את ארבעת השחקנים שהשתתפו במשחק.
        sa.Column("team_a_player_1", sa.String(length=100), nullable=False),
        sa.Column("team_a_player_2", sa.String(length=100), nullable=False),
        sa.Column("team_b_player_1", sa.String(length=100), nullable=False),
        sa.Column("team_b_player_2", sa.String(length=100), nullable=False),

        # שומר את מספר המערכות שכל קבוצה ניצחה בהן.
        sa.Column("team_a_sets", sa.Integer(), nullable=False),
        sa.Column("team_b_sets", sa.Integer(), nullable=False),

        # שומר הערה אופציונלית באורך מוגבל.
        sa.Column("notes", sa.String(length=500), nullable=True),

        # מונע תוצאות שליליות ותוצאת תיקו במערכות.
        sa.CheckConstraint(
            "team_a_sets <> team_b_sets",
            name="ck_matches_sets_not_tied",
        ),
        sa.CheckConstraint(
            "team_a_sets >= 0",
            name="ck_matches_team_a_sets_nonnegative",
        ),
        sa.CheckConstraint(
            "team_b_sets >= 0",
            name="ck_matches_team_b_sets_nonnegative",
        ),

        # מגדיר את המזהה כמפתח הראשי של הטבלה.
        sa.PrimaryKeyConstraint("id"),
    )


# מוחק את טבלת המשחקים בעת חזרה לגרסת מסד נתונים קודמת.
def downgrade() -> None:
    # מסיר את טבלת המשחקים ואת הנתונים שבתוכה.
    op.drop_table("matches")
