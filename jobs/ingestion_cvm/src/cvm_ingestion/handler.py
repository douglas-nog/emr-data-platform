from __future__ import annotations

import logging
import os

from cvm_ingestion.cvm_client import CvmRequest, fetch_report
from cvm_ingestion.landing_writer import write_landing

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_LANDING_BUCKET_ENV = "LANDING_BUCKET"


class EventError(ValueError):
    """Raised when the invocation event is missing or malformed."""


def _parse_event(event: dict) -> CvmRequest:
    try:
        return CvmRequest(year_month=str(event["year_month"]))
    except KeyError as exc:
        raise EventError(f"missing required field: {exc.args[0]}") from exc
    except ValueError as exc:
        raise EventError(str(exc)) from exc


def handler(event: dict, context=None) -> dict:
    bucket = os.environ.get(_LANDING_BUCKET_ENV)
    if not bucket:
        raise EventError(
            f"{_LANDING_BUCKET_ENV} environment variable is not set")

    request = _parse_event(event)
    csv_text = fetch_report(request)
    landed = write_landing(csv_text, request.year_month, bucket)

    return {
        "year_month": request.year_month,
        "bucket": landed.bucket,
        "key": landed.key,
        "byte_count": landed.byte_count,
    }
