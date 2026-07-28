from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

# The SGS API rejects date ranges wider than 10 years, so requests are sliced.
_MAX_WINDOW_YEARS = 10

_BASE_URL = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.{series_code}/dados"
_DATE_FMT = "%d/%m/%Y"
_RETRY_STATUSES = (429, 500, 502, 503, 504)


@dataclass(frozen=True)
class SgsRequest:
    """A single fetch instruction for one series over a date range."""

    series_code: int
    start: date
    end: date

    def __post_init__(self) -> None:
        if self.start > self.end:
            raise ValueError(f"start {self.start} is after end {self.end}")


def _build_session(
    total_retries: int = 3,
    backoff_factor: float = 1.0,
) -> requests.Session:
    """Session with retry and backoff on transient errors (backoff 0s, 2s, 4s)."""
    retry = Retry(
        total=total_retries,
        status_forcelist=_RETRY_STATUSES,
        allowed_methods=frozenset(["GET"]),
        backoff_factor=backoff_factor,
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session = requests.Session()
    session.mount("https://", adapter)
    return session


def _iter_windows(
    start: date, end: date, max_years: int = _MAX_WINDOW_YEARS
) -> list[tuple[date, date]]:
    """Split [start, end] into windows no wider than max_years. Pure, testable."""
    windows: list[tuple[date, date]] = []
    window_start = start
    while window_start <= end:
        try:
            boundary = window_start.replace(year=window_start.year + max_years)
        except ValueError:
            # Feb 29 has no counterpart in a non-leap target year.
            boundary = window_start.replace(
                year=window_start.year + max_years, day=28
            )
        window_end = min(end, boundary - timedelta(days=1))
        windows.append((window_start, window_end))
        window_start = window_end + timedelta(days=1)
    return windows


def _build_url(series_code: int, base_url: str) -> str:
    return base_url.format(series_code=series_code)


def _params(window_start: date, window_end: date) -> dict[str, str]:
    return {
        "formato": "json",
        "dataInicial": window_start.strftime(_DATE_FMT),
        "dataFinal": window_end.strftime(_DATE_FMT),
    }


def fetch_series(
    request: SgsRequest,
    session: requests.Session | None = None,
    timeout: tuple[int, int] = (30, 60),
    base_url: str = _BASE_URL,
) -> list[dict[str, str]]:
    """Fetch a series' observations across the range, raw and unconverted.

    session is injectable so tests can pass a mock; timeout is (connect, read).
    """
    session = session or _build_session()
    url = _build_url(request.series_code, base_url)
    records: list[dict[str, str]] = []

    for window_start, window_end in _iter_windows(request.start, request.end):
        logger.info(
            "Fetching series %s from %s to %s",
            request.series_code,
            window_start,
            window_end,
        )
        response = session.get(
            url, params=_params(window_start, window_end), timeout=timeout
        )
        response.raise_for_status()
        batch = response.json()

        if not isinstance(batch, list):
            raise ValueError(
                f"Unexpected payload for series {request.series_code}: "
                f"expected a JSON array, got {type(batch).__name__}"
            )
        records.extend(batch)

    logger.info(
        "Fetched %d records for series %s", len(records), request.series_code
    )
    return records
