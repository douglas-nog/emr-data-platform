from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock

import pytest
import requests

from bcb_ingestion.sgs_client import (
    SgsRequest,
    _iter_windows,
    fetch_series,
)


class TestSgsRequest:
    def test_valid_range(self):
        req = SgsRequest(11, date(2020, 1, 1), date(2025, 1, 1))
        assert req.series_code == 11

    def test_start_after_end_raises(self):
        with pytest.raises(ValueError, match="after end"):
            SgsRequest(11, date(2025, 1, 1), date(2020, 1, 1))

    def test_same_day_range_is_valid(self):
        req = SgsRequest(11, date(2025, 1, 1), date(2025, 1, 1))
        assert req.start == req.end


class TestIterWindows:
    def test_five_year_range_is_single_window(self):
        windows = _iter_windows(date(2021, 1, 1), date(2025, 12, 31))
        assert windows == [(date(2021, 1, 1), date(2025, 12, 31))]

    def test_exactly_ten_years_is_single_window(self):
        windows = _iter_windows(date(2015, 1, 1), date(2024, 12, 31))
        assert len(windows) == 1

    def test_eleven_years_splits_into_two(self):
        windows = _iter_windows(date(2014, 1, 1), date(2024, 12, 31))
        assert len(windows) == 2
        # Windows are contiguous and non-overlapping.
        assert windows[0][1] < windows[1][0]
        assert (windows[1][0] - windows[0][1]).days == 1
        # Coverage is complete.
        assert windows[0][0] == date(2014, 1, 1)
        assert windows[-1][1] == date(2024, 12, 31)

    def test_leap_day_start_does_not_crash(self):
        # Feb 29, 2020 + 10 years lands on a non-leap year (2030).
        windows = _iter_windows(date(2020, 2, 29), date(2035, 1, 1))
        assert len(windows) == 2
        # First window ends the day before the boundary; the boundary fell back
        # to Feb 28, so the last day of the first window is Feb 27, 2030.
        assert windows[0][1] == date(2030, 2, 27)
        assert windows[1][0] == date(2030, 2, 28)

    def test_single_day(self):
        windows = _iter_windows(date(2025, 6, 15), date(2025, 6, 15))
        assert windows == [(date(2025, 6, 15), date(2025, 6, 15))]


def _mock_session(payloads):
    """Session whose GET returns each payload in turn."""
    session = MagicMock(spec=requests.Session)
    responses = []
    for payload in payloads:
        resp = MagicMock()
        resp.json.return_value = payload
        resp.raise_for_status.return_value = None
        responses.append(resp)
    session.get.side_effect = responses
    return session


class TestFetchSeries:
    def test_single_window_returns_records(self):
        records = [{"data": "01/01/2025", "valor": "0.045"}]
        session = _mock_session([records])
        req = SgsRequest(11, date(2025, 1, 1), date(2025, 1, 31))

        result = fetch_series(req, session=session)

        assert result == records
        session.get.assert_called_once()

    def test_records_are_returned_raw(self):
        records = [{"data": "01/01/2025", "valor": "0.045513"}]
        session = _mock_session([records])
        req = SgsRequest(11, date(2025, 1, 1), date(2025, 1, 2))

        result = fetch_series(req, session=session)

        # No conversion: strings stay strings, exactly as delivered.
        assert result[0]["valor"] == "0.045513"
        assert result[0]["data"] == "01/01/2025"

    def test_multiple_windows_are_concatenated(self):
        batch_1 = [{"data": "01/01/2014", "valor": "1"}]
        batch_2 = [{"data": "01/01/2024", "valor": "2"}]
        session = _mock_session([batch_1, batch_2])
        req = SgsRequest(11, date(2014, 1, 1), date(2024, 12, 31))

        result = fetch_series(req, session=session)

        assert result == batch_1 + batch_2
        assert session.get.call_count == 2

    def test_non_list_payload_raises(self):
        session = _mock_session([{"error": "unexpected"}])
        req = SgsRequest(11, date(2025, 1, 1), date(2025, 1, 2))

        with pytest.raises(ValueError, match="expected a JSON array"):
            fetch_series(req, session=session)

    def test_http_error_propagates(self):
        session = MagicMock(spec=requests.Session)
        resp = MagicMock()
        resp.raise_for_status.side_effect = requests.HTTPError("500")
        session.get.return_value = resp
        req = SgsRequest(11, date(2025, 1, 1), date(2025, 1, 2))

        with pytest.raises(requests.HTTPError):
            fetch_series(req, session=session)
