# בוחר תמונת בסיס קלה עם Python 3.12.
FROM python:3.12-slim

# מונע קובצי מטמון ושולח פלט ישירות ליומן.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# מגדיר את תיקיית העבודה בתוך המכולה.
WORKDIR /app

# יוצר משתמש מוגבל להרצת השירות.
RUN addgroup --system app && adduser --system --ingroup app app

# מעתיק תחילה את רשימת הספריות כדי לנצל שכבות מטמון.
COPY requirements.txt .

# מתקין רק את ספריות ההרצה הנחוצות לשירות.
RUN pip install --no-cache-dir -r requirements.txt

# מעתיק את קוד השירות ואת כלי המיגרציות.
COPY --chown=app:app src ./src
COPY --chown=app:app migrations ./migrations
COPY --chown=app:app alembic.ini .

# מעביר את ההרצה למשתמש שאינו מנהל.
USER app

# מתעד את הפורט שהשירות מקשיב לו.
EXPOSE 8000

# מפעיל את שירות ה־API בתוך המכולה.
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
