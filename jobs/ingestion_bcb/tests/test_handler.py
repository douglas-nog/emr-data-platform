from __future__ import annotations

from datetime import date, datetime, timezone
from unittest.mock import patch

import pytest

from bcb_ingestion import handler as handler_module
from bcb_ingestion.handler import EventError, _parse_event, handler
from bcb_ingestion.landing_writer import LandingObject


class TestParseEvent:
    def test_valid_event_with_explicit_end(self):
        req = _parse_event(
            {"series_code": 11, "start": "2020-01-01", "end": "2025-01-01"})
        assert req.series_code == 11
        assert req.start == date(2020, 1, 1)
        assert req.end == date(2025, 1, 1)

    def test_end_defaults_to_today(self):
        req = _parse_event({"series_code": 11, "start": "2020-01-01"})
        assert req.end == datetime.now(timezone.utc).date()

    def test_series_code_as_string_is_coerced(self):
        req = _parse_event({"series_code": "11", "start": "2020-01-01"})
        assert req.series_code == 11

    def test_missing_series_code_raises(self):
        with pytest.raises(EventError, match="missing required field"):
            _parse_event({"start": "2020-01-01"})

    def test_missing_start_raises(self):
        with pytest.raises(EventError, match="missing required field"):
            _parse_event({"series_code": 11})

    def test_invalid_date_raises(self):
        with pytest.raises(EventError, match="invalid field value"):
            _parse_event({"series_code": 11, "start": "not-a-date"})

    def test_non_numeric_series_raises(self):
        with pytest.raises(EventError, match="invalid field value"):
            _parse_event({"series_code": "abc", "start": "2020-01-01"})


class TestHandler:
    _EVENT = {"series_code": 11, "start": "2025-01-01", "end": "2025-01-31"}

    def test_happy_path(self, monkeypatch):
        monkeypatch.setenv("LANDING_BUCKET", "my-bucket")
        records = [{"data": "01/01/2025", "valor": "0.045"}]

        with patch.object(
            handler_module, "fetch_series", return_value=records
        ) as fetch, patch.object(
            handler_module,
            "write_landing",
            return_value=LandingObject("my-bucket", "some/key.json", 1),
        ) as write:
            result = handler(self._EVENT)

        fetch.assert_called_once()
        write.assert_called_once()
        assert result["series_code"] == 11
        assert result["bucket"] == "my-bucket"
        assert result["record_count"] == 1

    def test_missing_bucket_env_raises(self, monkeypatch):
        monkeypatch.delenv("LANDING_BUCKET", raising=False)
        with pytest.raises(EventError, match="LANDING_BUCKET"):
            handler(self._EVENT)

    def test_bad_event_raises_before_fetch(self, monkeypatch):
        monkeypatch.setenv("LANDING_BUCKET", "my-bucket")
        with patch.object(handler_module, "fetch_series") as fetch:
            with pytest.raises(EventError):
                handler({"start": "2025-01-01"})
        fetch.assert_not_called()
