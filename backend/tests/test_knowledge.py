import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient
from google.genai import types

from backend.knowledge import DEFAULT_WARD_PDF, KnowledgeIntegrityError, read_verified_pdf
from backend.main import app

PAYLOAD = {"session_id": "f5be299b-157d-4f35-9364-68256ca93bcf", "message": "जन्म दर्ता"}
PDF_URI = "https://generativelanguage.googleapis.com/v1beta/files/test"
CLARIFICATION = """
    {"action": "WARD_OFFICE_GUIDANCE", "coverage": "verified",
     "ward_service": "birth_registration", "needs_clarification": true,
     "follow_up_question_nepali": "तपाईंसँग अस्पतालको जन्म प्रतिवेदन छ?",
     "quick_replies_nepali": ["छ", "छैन"],
     "source": {"page": 2, "excerpt": "Hospital birth report / Birth notification slip"}}
"""


class KnowledgeIntegrityTests(unittest.TestCase):
    def test_rejects_same_size_tampering_and_missing_file(self):
        original = read_verified_pdf(DEFAULT_WARD_PDF)
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / DEFAULT_WARD_PDF.name
            copy.write_bytes(original[:-1] + bytes([original[-1] ^ 1]))
            with self.assertRaisesRegex(KnowledgeIntegrityError, "ward_kb_integrity_failure"):
                read_verified_pdf(copy)
            copy.unlink()
            with self.assertRaisesRegex(KnowledgeIntegrityError, "missing_ward_kb"):
                read_verified_pdf(copy)

    def test_rejects_symlink_to_approved_pdf(self):
        with tempfile.TemporaryDirectory() as directory:
            alias = Path(directory) / DEFAULT_WARD_PDF.name
            alias.symlink_to(DEFAULT_WARD_PDF)
            with self.assertRaisesRegex(KnowledgeIntegrityError, "ward_kb_integrity_failure"):
                read_verified_pdf(alias)

    def test_pdf_prefix_citations_sessions_and_runtime_integrity(self):
        original = read_verified_pdf(DEFAULT_WARD_PDF)

        async def upload(*, file, config):
            self.assertEqual(file.read(), original)
            self.assertEqual(config.mime_type, "application/pdf")
            return types.File(uri=PDF_URI, state="ACTIVE")

        generate = AsyncMock(return_value=SimpleNamespace(text=CLARIFICATION))
        sdk = SimpleNamespace(aio=SimpleNamespace(
            files=SimpleNamespace(upload=upload),
            models=SimpleNamespace(generate_content=generate),
            aclose=AsyncMock(),
        ))
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / DEFAULT_WARD_PDF.name
            copy.write_bytes(original)
            with (
                patch.dict(os.environ, {"WARD_KB_PATH": str(copy), "GEMINI_API_KEY": "test"}),
                patch("backend.main.genai.Client", return_value=sdk),
                TestClient(app) as api,
            ):
                self.assertEqual(api.get("/health").json(), {"assistant": "ready"})
                response = api.post("/assistant", json=PAYLOAD)
                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.json()["needs_clarification"])
                contents = generate.call_args.kwargs["contents"]
                self.assertEqual(contents[0].parts[0].file_data.file_uri, PDF_URI)

                follow_up = api.post("/assistant", json={**PAYLOAD, "message": "छ"})
                self.assertEqual(follow_up.status_code, 200)
                contents = generate.call_args.kwargs["contents"]
                self.assertEqual([item.role for item in contents], ["user", "user", "model", "user"])
                self.assertEqual(contents[0].parts[0].file_data.file_uri, PDF_URI)
                self.assertEqual(contents[-1].parts[0].text, "छ")

                wrong_citation = CLARIFICATION.replace('"page": 2', '"page": 1')
                generate.return_value = SimpleNamespace(text=wrong_citation)
                fallback = api.post("/assistant", json=PAYLOAD)
                self.assertEqual(fallback.json()["coverage"], "out_of_scope")
                copy.write_bytes(original[:-1] + bytes([original[-1] ^ 1]))
                self.assertEqual(api.get("/health").json(), {"assistant": "ward_kb_integrity_failure"})
                self.assertEqual(api.post("/assistant", json=PAYLOAD).status_code, 503)
                self.assertEqual(generate.await_count, 3)

    def test_rejects_answer_if_pdf_disappears_during_generation(self):
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / DEFAULT_WARD_PDF.name
            copy.write_bytes(read_verified_pdf(DEFAULT_WARD_PDF))

            async def generate(**kwargs):
                copy.unlink()
                return SimpleNamespace(text=CLARIFICATION)

            sdk = SimpleNamespace(aio=SimpleNamespace(
                files=SimpleNamespace(upload=AsyncMock(return_value=types.File(uri=PDF_URI))),
                models=SimpleNamespace(generate_content=generate),
                aclose=AsyncMock(),
            ))
            with (
                patch.dict(os.environ, {"WARD_KB_PATH": str(copy), "GEMINI_API_KEY": "test"}),
                patch("backend.main.genai.Client", return_value=sdk),
                TestClient(app) as api,
            ):
                self.assertEqual(api.post("/assistant", json=PAYLOAD).status_code, 503)
                self.assertEqual(api.get("/health").json(), {"assistant": "missing_ward_kb"})
