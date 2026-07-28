from __future__ import annotations

import io
import zipfile
from unittest.mock import MagicMock

import pytest
import requests

from cvm_ingestion.cvm_client import (
    CvmRequest,
    _build_url,
    extract_csv,
    fetch_report,
)


def _make_zip(files: dict[str, str], encoding: str = "iso-8859-1") -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        for name, content in files.items():
            archive.writestr(name, content.encode(encoding))
    return buffer.getvalue()


class TestCvmRequest:
    def test_valid(self):
        assert CvmRequest("202505").year_month == "202505"

    @pytest.mark.parametrize("bad", ["2025-05", "20255", "2025013", "abcdef", ""])
    def test_malformed_raises(self, bad):
        with pytest.raises(ValueError, match="YYYYMM"):
            CvmRequest(bad)

    @pytest.mark.parametrize("bad", ["202500", "202513"])
    def test_invalid_month_raises(self, bad):
        with pytest.raises(ValueError, match="invalid month"):
            CvmRequest(bad)


class TestBuildUrl:
    def test_url_has_year_month(self):
        url = _build_url("202505", "https://x/inf_diario_fi_{year_month}.zip")
        assert url == "https://x/inf_diario_fi_202505.zip"


class TestExtractCsv:
    def test_extracts_single_csv(self):
        zip_bytes = _make_zip({"inf_diario_fi_202505.csv": "col1;col2\na;b"})
        result = extract_csv(zip_bytes)
        assert result == "col1;col2\na;b"

    def test_preserves_latin1_characters(self):
        content = "nome;valor\nfundação;1,5"
        zip_bytes = _make_zip({"data.csv": content})
        assert extract_csv(zip_bytes) == content

    def test_no_csv_raises(self):
        zip_bytes = _make_zip({"readme.txt": "not a csv"})
        with pytest.raises(ValueError, match="exactly one CSV"):
            extract_csv(zip_bytes)

    def test_multiple_csv_raises(self):
        zip_bytes = _make_zip({"a.csv": "x", "b.csv": "y"})
        with pytest.raises(ValueError, match="exactly one CSV"):
            extract_csv(zip_bytes)


class TestFetchReport:
    def test_returns_csv_text(self):
        zip_bytes = _make_zip({"inf.csv": "col1;col2\n1;2"})
        session = MagicMock(spec=requests.Session)
        resp = MagicMock()
        resp.content = zip_bytes
        resp.raise_for_status.return_value = None
        session.get.return_value = resp

        result = fetch_report(CvmRequest("202505"), session=session)

        assert result == "col1;col2\n1;2"
        session.get.assert_called_once()

    def test_http_error_propagates(self):
        session = MagicMock(spec=requests.Session)
        resp = MagicMock()
        resp.raise_for_status.side_effect = requests.HTTPError("404")
        session.get.return_value = resp

        with pytest.raises(requests.HTTPError):
            fetch_report(CvmRequest("202505"), session=session)
