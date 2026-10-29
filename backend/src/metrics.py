# מייבא מדידת זמן מדויקת עבור זמני תגובה.
from time import perf_counter

# מייבא את סוגי הבקשות והתשובות של FastAPI.
from fastapi import Request, Response

# מייבא מדדים ואת אפליקציית המדדים של Prometheus.
from prometheus_client import Counter, Histogram, make_asgi_app


# סופר את כל בקשות ה־HTTP שהגיעו ל־API.
HTTP_REQUESTS = Counter(
    "padel_api_http_requests",
    "Total HTTP requests handled by the Padel API.",
    ["method", "route", "status_code"],
)

# מודד את משך הטיפול בבקשות ה־HTTP בשניות.
HTTP_REQUEST_DURATION_SECONDS = Histogram(
    "padel_api_http_request_duration_seconds",
    "HTTP request duration in seconds for the Padel API.",
    ["method", "route"],
)

# סופר בקשות שהסתיימו בשגיאה מצד הלקוח או מצד השרת.
HTTP_REQUEST_ERRORS = Counter(
    "padel_api_http_errors",
    "Total HTTP requests that returned an error status.",
    ["method", "route", "status_code"],
)

# יוצר אפליקציית ASGI ייעודית שמחזירה את המדדים בנתיב /metrics.
metrics_app = make_asgi_app()


# מחזיר נתיב כללי במקום מזהה ייחודי של משחק.
def get_route_label(request: Request) -> str:
    route = request.scope.get("route")

    if route is not None and hasattr(route, "path"):
        return str(route.path)

    return request.url.path


# מודד בקשה אחת ומחזיר את תשובת השירות המקורית.
async def observe_request(request: Request, call_next) -> Response:
    # לא סופר את Prometheus עצמו, עם או בלי לוכסן מסיים.
    if request.url.path in {"/metrics", "/metrics/"}:
        return await call_next(request)

    # שומר את רגע תחילת הטיפול בבקשה.
    started_at = perf_counter()

    try:
        # מעביר את הבקשה להמשך הטיפול של FastAPI.
        response = await call_next(request)
    except Exception:
        # מתעד חריגה לא מטופלת כשגיאת שרת לפני שמחזירים אותה הלאה.
        duration = perf_counter() - started_at
        route = get_route_label(request)

        HTTP_REQUESTS.labels(
            method=request.method,
            route=route,
            status_code="500",
        ).inc()

        HTTP_REQUEST_DURATION_SECONDS.labels(
            method=request.method,
            route=route,
        ).observe(duration)

        HTTP_REQUEST_ERRORS.labels(
            method=request.method,
            route=route,
            status_code="500",
        ).inc()

        raise

    # מחשב את משך הטיפול לאחר שהשירות החזיר תשובה.
    duration = perf_counter() - started_at
    route = get_route_label(request)
    status_code = str(response.status_code)

    # מעדכן את מונה הבקשות הכולל.
    HTTP_REQUESTS.labels(
        method=request.method,
        route=route,
        status_code=status_code,
    ).inc()

    # מעדכן את מדד זמן התגובה.
    HTTP_REQUEST_DURATION_SECONDS.labels(
        method=request.method,
        route=route,
    ).observe(duration)

    # סופר כל תשובת שגיאה, כולל 4xx ו־5xx.
    if response.status_code >= 400:
        HTTP_REQUEST_ERRORS.labels(
            method=request.method,
            route=route,
            status_code=status_code,
        ).inc()

    return response
