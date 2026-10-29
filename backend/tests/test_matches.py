# מייבא את לקוח הבדיקות של השירות.
from fastapi.testclient import TestClient  # לקוח פנימי לבדיקות השירות.


# מחזיר מידע תקין שאפשר לשלוח ליצירת משחק.
def valid_match_payload() -> dict[str, object]:
    return {
        "played_at": "2024-10-24T18:30:00Z",
        "team_a": ["Aviv", "Daniel"],
        "team_b": ["Noam", "Eyal"],
        "team_a_sets": 2,
        "team_b_sets": 1,
        "notes": "Evening match",
    }


# בודק שהשירות עצמו פעיל.
def test_liveness_returns_ok(client: TestClient) -> None:
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


# בודק שהשירות מוכן לעבוד עם מסד הנתונים.
def test_readiness_returns_ok(client: TestClient) -> None:
    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


# בודק שיצירת משחק תקין מחזירה תשובה מלאה.
def test_create_match_returns_created_match(client: TestClient) -> None:
    payload = valid_match_payload()

    response = client.post("/api/v1/matches", json=payload)

    assert response.status_code == 201

    match = response.json()
    assert match["team_a"] == payload["team_a"]
    assert match["team_b"] == payload["team_b"]
    assert match["team_a_sets"] == 2
    assert match["team_b_sets"] == 1
    assert match["winner"] == "team_a"
    assert match["id"]
    assert match["created_at"]


# בודק שהמשחקים מוחזרים מהחדש לישן.
def test_list_matches_returns_newest_first(client: TestClient) -> None:
    older_match = valid_match_payload()
    older_match["played_at"] = "2024-10-23T18:30:00Z"
    older_match["notes"] = "Older match"

    newer_match = valid_match_payload()
    newer_match["played_at"] = "2024-10-24T18:30:00Z"
    newer_match["notes"] = "Newer match"

    assert client.post("/api/v1/matches", json=older_match).status_code == 201
    assert client.post("/api/v1/matches", json=newer_match).status_code == 201

    response = client.get("/api/v1/matches")

    assert response.status_code == 200

    matches = response.json()
    assert len(matches) == 2
    assert [match["notes"] for match in matches] == [
        "Newer match",
        "Older match",
    ]


# בודק ששחקן אינו יכול להופיע בשתי קבוצות באותו משחק.
def test_create_match_rejects_duplicate_player(client: TestClient) -> None:
    payload = valid_match_payload()
    payload["team_b"] = ["Noam", "Aviv"]

    response = client.post("/api/v1/matches", json=payload)

    assert response.status_code == 422

    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["message"] == "The request contains invalid data."
    assert error["fields"] == [
        {
            "field": "body",
            "message": "a player cannot appear more than once",
        }
    ]


# בודק שמחיקת משחק מסירה אותו ממסד הנתונים.
def test_delete_match_removes_match(client: TestClient) -> None:
    create_response = client.post(
        "/api/v1/matches",
        json=valid_match_payload(),
    )
    match_id = create_response.json()["id"]

    response = client.delete(f"/api/v1/matches/{match_id}")

    assert response.status_code == 204
    assert response.content == b""

    matches_response = client.get("/api/v1/matches")
    assert matches_response.status_code == 200
    assert matches_response.json() == []


# בודק שמחיקה של משחק שאינו קיים מחזירה תשובה ברורה.
def test_delete_missing_match_returns_not_found(client: TestClient) -> None:
    missing_match_id = "00000000-0000-0000-0000-000000000000"

    response = client.delete(f"/api/v1/matches/{missing_match_id}")

    assert response.status_code == 404
    assert response.json() == {"detail": "match not found"}
