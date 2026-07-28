from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone

import boto3

logger = logging.getLogger(__name__)

_CSV_ENCODING = "iso-8859-1"


@dataclass(frozen=True)
class LandingObject:

    bucket: str
    key: str
    byte_count: int


def _ingestion_timestamp() -> datetime:
    return datetime.now(timezone.utc)


def build_key(year_month: str, ingested_at: datetime) -> str:
    ingestion_date = ingested_at.strftime("%Y-%m-%d")
    epoch_ms = int(ingested_at.timestamp() * 1000)
    return f"year_month={year_month}/ingestion_date={ingestion_date}/{epoch_ms}.csv"


def write_landing(
    csv_text: str,
    year_month: str,
    bucket: str,
    s3_client=None,
    ingested_at: datetime | None = None,
) -> LandingObject:
    s3_client = s3_client or boto3.client("s3")
    ingested_at = ingested_at or _ingestion_timestamp()

    key = build_key(year_month, ingested_at)
    body = csv_text.encode(_CSV_ENCODING)
    tagging = f"year_month={year_month}&ingested_at={ingested_at.isoformat()}"

    logger.info(
        "Writing %d bytes for %s to s3://%s/%s",
        len(body),
        year_month,
        bucket,
        key,
    )
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=body,
        ContentType="text/csv",
        Tagging=tagging,
    )
    return LandingObject(bucket=bucket, key=key, byte_count=len(body))
