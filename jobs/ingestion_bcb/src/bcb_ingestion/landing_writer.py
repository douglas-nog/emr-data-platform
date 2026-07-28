from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone

import boto3

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class LandingObject:
    """Where a write landed, returned to the caller for reporting."""

    bucket: str
    key: str
    record_count: int


def _ingestion_timestamp() -> datetime:
    return datetime.now(timezone.utc)


def build_key(series_code: int, ingested_at: datetime) -> str:
    """Build the Landing S3 key: series=<code>/ingestion_date=<date>/<epoch_ms>.json.

    The epoch suffix makes each run a distinct object, so re-running never
    overwrites a prior capture.
    """
    ingestion_date = ingested_at.strftime("%Y-%m-%d")
    epoch_ms = int(ingested_at.timestamp() * 1000)
    return f"series={series_code}/ingestion_date={ingestion_date}/{epoch_ms}.json"


def _serialize(
    records: list[dict[str, str]],
    series_code: int,
    ingested_at: datetime,
) -> bytes:
    """Wrap the raw records with ingestion metadata as UTF-8 JSON bytes."""
    envelope = {
        "series_code": series_code,
        "ingested_at": ingested_at.isoformat(),
        "record_count": len(records),
        "data": records,
    }
    return json.dumps(envelope, ensure_ascii=False).encode("utf-8")


def write_landing(
    records: list[dict[str, str]],
    series_code: int,
    bucket: str,
    s3_client=None,
    ingested_at: datetime | None = None,
) -> LandingObject:
    """Write raw records to the Landing bucket.

    s3_client is injectable so tests can pass a mock; when omitted, the default
    client uses the ambient credentials (execution role in Lambda).
    """
    s3_client = s3_client or boto3.client("s3")
    ingested_at = ingested_at or _ingestion_timestamp()

    key = build_key(series_code, ingested_at)
    body = _serialize(records, series_code, ingested_at)

    logger.info(
        "Writing %d records for series %s to s3://%s/%s",
        len(records),
        series_code,
        bucket,
        key,
    )
    s3_client.put_object(
        Bucket=bucket, Key=key, Body=body, ContentType="application/json"
    )
    return LandingObject(bucket=bucket, key=key, record_count=len(records))
