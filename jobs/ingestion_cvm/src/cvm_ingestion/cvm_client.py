from __future__ import annotations

import io
import logging
import zipfile
from dataclasses import dataclass

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

_BASE_URL = "https://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS/inf_diario_fi_{year_month}.zip"
_CSV_ENCODING = "iso-8859-1"
_RETRY_STATUSES = (429, 500, 502, 503, 504)


@dataclass(frozen=True)
class CvmRequest:
    year_month: str

    def __post_init__(self) -> None:
        if not (len(self.year_month) == 6 and self.year_month.isdigit()):
            raise ValueError(
                f"year_month must be YYYYMM, got {self.year_month!r}")
        month = int(self.year_month[4:])
        if not 1 <= month <= 12:
            raise ValueError(f"invalid month in {self.year_month!r}")


def _build_session(total_retries: int = 3, backoff_factor: float = 1.0) -> requests.Session:
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


def _build_url(year_month: str, base_url: str) -> str:
    return base_url.format(year_month=year_month)


def extract_csv(zip_bytes: bytes) -> str:
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
        names = [n for n in archive.namelist() if n.lower().endswith(".csv")]
        if len(names) != 1:
            raise ValueError(
                f"expected exactly one CSV in the archive, found {names}"
            )
        raw = archive.read(names[0])
    return raw.decode(_CSV_ENCODING)


def fetch_report(
    request: CvmRequest,
    session: requests.Session | None = None,
    timeout: tuple[int, int] = (30, 120),
    base_url: str = _BASE_URL,
) -> str:
    session = session or _build_session()
    url = _build_url(request.year_month, base_url)

    logger.info("Fetching CVM daily report for %s", request.year_month)
    response = session.get(url, timeout=timeout)
    response.raise_for_status()

    csv_text = extract_csv(response.content)
    logger.info(
        "Extracted CSV for %s (%d characters)", request.year_month, len(
            csv_text)
    )
    return csv_text
