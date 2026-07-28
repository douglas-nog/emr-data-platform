from __future__ import annotations

from unittest.mock import patch

import pytest

from cvm_ingestion import handler as handler_module
from cvm_ingestion.handler import EventError, _parse_event, handler
from cvm_ingestion.landing_writer import LandingObject


class TestParseEvent:
    def test_valid(self):
        req = _parse_event({"year_month": "202505"})
        assert req.year_month == "202505"

    def test_integer_year_month_coerced(self):
        req = _parse_event({"year_month": 202505})
        assert req.year_month == "202505"

    def test_missing_raises(self):
        with pytest.raises(EventError, match="missing required field"):
            _parse_event({})

    def test_malformed_raises(self):
        with pytest.raises(EventError, match="YYYYMM"):
            _parse_event({"year_month": "2025-05"})


class TestHandler:
    _EVENT = {"year_month": "202505"}

    def test_happy_path(self, monkeypatch):
        monkeypatch.setenv("LANDING_BUCKET", "my-bucket")
        with patch.object(handler_module, "fetch_report", return_value="csv") as fetch, patch.object(
            handler_module, "write_landing",
            return_value=LandingObject("my-bucket", "some/key.csv", 3),
        ) as write:
            result = handler(self._EVENT)

        fetch.assert_called_once()
        write.assert_called_once()
        assert result["year_month"] == "202505"
        assert result["byte_count"] == 3

    def test_missing_bucket_raises(self, monkeypatch):
        monkeypatch.delenv("LANDING_BUCKET", raising=False)
        with pytest.raises(EventError, match="LANDING_BUCKET"):
            handler(self._EVENT)

    def test_bad_event_raises_before_fetch(self, monkeypatch):
        monkeypatch.setenv("LANDING_BUCKET", "my-bucket")
        with patch.object(handler_module, "fetch_report") as fetch:
            with pytest.raises(EventError):
                handler({"year_month": "bad"})
        fetch.assert_not_called()
