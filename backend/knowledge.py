import hashlib
import hmac
import os
import stat
from pathlib import Path

DEFAULT_WARD_PDF = Path(__file__).with_name("reference") / "ward_office_kb.pdf"
WARD_PDF_SHA256 = "aa082a4ec12b0f918659d3799c89f53893bb2fb95f6b371a38cf28e3af234b2d"
WARD_PDF_SIZE = 363973


class KnowledgeIntegrityError(Exception):
    def __init__(self, status: str):
        self.status = status
        super().__init__(status)


def read_verified_pdf(path: Path) -> bytes:
    try:
        if path.is_symlink():
            raise KnowledgeIntegrityError("ward_kb_integrity_failure")
        flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
        descriptor = os.open(path, flags | getattr(os, "O_BINARY", 0))
        with os.fdopen(descriptor, "rb") as file:
            details = os.fstat(file.fileno())
            if not stat.S_ISREG(details.st_mode) or details.st_size != WARD_PDF_SIZE:
                raise KnowledgeIntegrityError("ward_kb_integrity_failure")
            content = file.read(WARD_PDF_SIZE + 1)
    except FileNotFoundError as exc:
        raise KnowledgeIntegrityError("missing_ward_kb") from exc
    except OSError as exc:
        raise KnowledgeIntegrityError("ward_kb_integrity_failure") from exc

    if not hmac.compare_digest(hashlib.sha256(content).hexdigest(), WARD_PDF_SHA256):
        raise KnowledgeIntegrityError("ward_kb_integrity_failure")
    return content
