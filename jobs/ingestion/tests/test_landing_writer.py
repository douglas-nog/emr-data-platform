from __future__ import annotations

import json
from datetime import datetime, timezone
from unittest.mock import MagicMock

from bcb_ingestion.landing_writer import (
    LandingObject,
    build_key,
    write_landing,
)

_FIXED_TS = datetime(2026, 7, 25, 22, 44, 12, 130783, tzinfo=timezone.utc)


class TestBuildKey:
    def test_key_layout(self):
        key = build_key(11, _FIXED_TS)
        assert key == "series=11/ingestion_date=2026-07-25/1785019452130.json"

    def test_key_is_deterministic_for_same_timestamp(self):
        assert build_key(11, _FIXED_TS) == build_key(11, _FIXED_TS)

    def test_different_series_differ(self):
        assert build_key(11, _FIXED_TS) != build_key(12, _FIXED_TS)


class TestWriteLanding:
    def test_put_object_called_with_expected_args(self):
        s3 = MagicMock()
        records = [{"data": "01/01/2025", "valor": "0.045"}]

        result = write_landing(
            records, 11, "my-bucket", s3_client=s3, ingested_at=_FIXED_TS
        )

        s3.put_object.assert_called_once()
        kwargs = s3.put_object.call_args.kwargs
        assert kwargs["Bucket"] == "my-bucket"
        assert kwargs["Key"] == "series=11/ingestion_date=2026-07-25/1785019452130.json"
        assert kwargs["ContentType"] == "application/json"

    def test_envelope_contents(self):
        s3 = MagicMock()
        records = [{"data": "01/01/2025", "valor": "0.045513"}]

        write_landing(records, 11, "b", s3_client=s3, ingested_at=_FIXED_TS)

        body = json.loads(s3.put_object.call_args.kwargs["Body"])
        assert body["series_code"] == 11
        assert body["ingested_at"] == _FIXED_TS.isoformat()
        assert body["record_count"] == 1
        # Raw records preserved untouched inside the envelope.
        assert body["data"] == records
        assert body["data"][0]["valor"] == "0.045513"

    def test_returns_landing_object(self):
        s3 = MagicMock()
        records = [{"a": "1"}, {"b": "2"}]

        result = write_landing(
            records, 11, "my-bucket", s3_client=s3, ingested_at=_FIXED_TS
        )

        assert isinstance(result, LandingObject)
        assert result.bucket == "my-bucket"
        assert result.record_count == 2

    def test_empty_records_still_writes(self):
        s3 = MagicMock()

        result = write_landing([], 11, "b", s3_client=s3,
                               ingested_at=_FIXED_TS)

        s3.put_object.assert_called_once()
        assert result.record_count == 0

    def test_body_is_utf8_bytes(self):
        s3 = MagicMock()
        write_landing(
            [{"x": "café"}], 11, "b", s3_client=s3, ingested_at=_FIXED_TS
        )
        body = s3.put_object.call_args.kwargs["Body"]
        assert isinstance(body, bytes)
        assert "café" in body.decode("utf-8")
