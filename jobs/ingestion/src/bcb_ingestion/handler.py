from __future__ import annotations

import logging
import os
from datetime import date, datetime, timezone

from bcb_ingestion.landing_writer import write_landing
from bcb_ingestion.sgs_client import SgsRequest, fetch_series

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_LANDING_BUCKET_ENV = "LANDING_BUCKET"


class EventError(ValueError):
    """Raised when the invocation event is missing or malformed."""


def _parse_event(event: dict) -> SgsRequest:
    """Turn the raw event into a validated SgsRequest.

    Required: series_code, start (YYYY-MM-DD). Optional: end, defaulting to
    today (UTC) so incremental runs can send only a start date.
    """
    try:
        series_code = int(event["series_code"])
        start = date.fromisoformat(event["start"])
    except KeyError as exc:
        raise EventError(f"missing required field: {exc.args[0]}") from exc
    except (TypeError, ValueError) as exc:
        raise EventError(f"invalid field value: {exc}") from exc

    end_raw = event.get("end")
    end = date.fromisoformat(
        end_raw) if end_raw else datetime.now(timezone.utc).date()

    return SgsRequest(series_code=series_code, start=start, end=end)


def handler(event: dict, context=None) -> dict:
    """Lambda entry point: fetch one series and write it to Landing.

    Returns the landed object's location and record count. Raises on bad input
    or downstream failure so the orchestrator can retry.
    """
    bucket = os.environ.get(_LANDING_BUCKET_ENV)
    if not bucket:
        raise EventError(
            f"{_LANDING_BUCKET_ENV} environment variable is not set")

    request = _parse_event(event)
    records = fetch_series(request)
    landed = write_landing(records, request.series_code, bucket)

    return {
        "series_code": request.series_code,
        "bucket": landed.bucket,
        "key": landed.key,
        "record_count": landed.record_count,
    }
