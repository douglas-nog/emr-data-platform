from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import MagicMock

from cvm_ingestion.landing_writer import LandingObject, build_key, write_landing

_FIXED_TS = datetime(2026, 7, 28, 12, 0, 0, tzinfo=timezone.utc)


class TestBuildKey:
    def test_key_layout(self):
        key = build_key("202505", _FIXED_TS)
        assert key.startswith("year_month=202505/ingestion_date=2026-07-28/")
        assert key.endswith(".csv")

    def test_different_months_differ(self):
        assert build_key("202505", _FIXED_TS) != build_key("202506", _FIXED_TS)


class TestWriteLanding:
    def test_put_object_args(self):
        s3 = MagicMock()
        result = write_landing("col1;col2\na;b", "202505",
                               "bucket", s3_client=s3, ingested_at=_FIXED_TS)

        kwargs = s3.put_object.call_args.kwargs
        assert kwargs["Bucket"] == "bucket"
        assert kwargs["ContentType"] == "text/csv"
        assert "year_month=202505" in kwargs["Tagging"]
        assert isinstance(result, LandingObject)

    def test_latin1_roundtrip(self):
        s3 = MagicMock()
        content = "nome;valor\nfundação;1,5"
        write_landing(content, "202505", "b",
                      s3_client=s3, ingested_at=_FIXED_TS)

        body = s3.put_object.call_args.kwargs["Body"]
        assert isinstance(body, bytes)
        assert body.decode("iso-8859-1") == content

    def test_byte_count_matches_body(self):
        s3 = MagicMock()
        result = write_landing("abc", "202505", "b",
                               s3_client=s3, ingested_at=_FIXED_TS)
        assert result.byte_count == len("abc".encode("iso-8859-1"))
