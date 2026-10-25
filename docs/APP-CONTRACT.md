# Application Contract

## Purpose

The first version of Padel Match Tracker allows users to create and view padel match results.

Authentication, player accounts, and racket tracking are intentionally out of scope for the first version.

## Match Model

A match contains:

- A server-generated unique identifier
- The date and time when the match was played
- Two players in team A
- Two players in team B
- The number of sets won by each team
- An optional note
- A winner calculated by the backend
- A server-generated creation timestamp

All date and time values use ISO 8601 format in UTC.

## Create a Match

```text
POST /api/v1/matches
```

Request body:

```json
{
  "played_at": "2026-10-25T18:30:00Z",
  "team_a": ["Aviv", "Daniel"],
  "team_b": ["Noam", "Eyal"],
  "team_a_sets": 2,
  "team_b_sets": 1,
  "notes": "Evening match in Ra'anana"
}
```

Successful response:

```json
{
  "id": "generated-uuid",
  "played_at": "2026-10-25T18:30:00Z",
  "team_a": ["Aviv", "Daniel"],
  "team_b": ["Noam", "Eyal"],
  "team_a_sets": 2,
  "team_b_sets": 1,
  "winner": "team_a",
  "notes": "Evening match in Ra'anana",
  "created_at": "2026-10-25T19:05:00Z"
}
```

## List Matches

```text
GET /api/v1/matches
```

The endpoint returns recorded matches, ordered from newest to oldest.

## Validation Rules

- Each team must contain exactly two players.
- Player names must not be empty.
- A player cannot appear in both teams.
- Set counts must be non-negative integers.
- The two teams cannot have the same number of sets.
- A completed match cannot have a future date.
- Notes are optional and limited to 500 characters.
- The backend calculates the winner from the set counts.

Invalid input returns HTTP status `422`.

## Health and Metrics Endpoints

```text
GET /health/live
GET /health/ready
GET /metrics
```

- `/health/live` confirms that the API process is running.
- `/health/ready` confirms that the API is running and can reach PostgreSQL.
- `/metrics` exposes Prometheus metrics for request count, request duration, and API errors.

## Security Rules

- No secret is accepted through the API request body.
- Database credentials are never stored in source code.
- During Kubernetes deployment, credentials will be injected through a Kubernetes Secret.
