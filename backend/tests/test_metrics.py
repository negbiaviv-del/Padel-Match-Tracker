# מייבא את לקוח הבדיקות של FastAPI.
from fastapi.testclient import TestClient


# בודק שנתיב המדדים חושף את מדדי ה־API שלנו.
def test_metrics_endpoint_exposes_application_metrics(
    client: TestClient,
) -> None:
    # יוצר בקשת API רגילה שתופיע במדדים.
    client.get("/health/live")

    # קורא את נתיב המדדים דרך אפליקציית Prometheus.
    response = client.get("/metrics/")

    # מוודא שהנתיב החזיר הצלחה ותוכן טקסטואלי של Prometheus.
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")

    # מוודא שמדד הבקשות שלנו אכן נחשף.
    assert "padel_api_http_requests_total" in response.text

    # מוודא שבקשת הבריאות נספרה כבקשת API רגילה.
    assert 'route="/health/live"' in response.text

    # מוודא שבקשת Prometheus עצמה אינה נספרת כתעבורת משתמשים.
    assert 'route="/metrics/"' not in response.text
