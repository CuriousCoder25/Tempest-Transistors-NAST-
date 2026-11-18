# Nagarik Sathi · नागरिक साथी

Flutter civic services demo with Nagarik AI, a FastAPI assistant backed by Gemini 2.5 Flash.

## Run the backend

Use Python 3.11 or later. From the project root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r backend/requirements.txt
cp .env.example .env
```

Set `GEMINI_API_KEY` in `.env` to enable live Gemini. Then load the environment and launch the API:

```bash
set -a
source .env
set +a
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

`GET /health` reports `ready` after the verified PDF is uploaded. The dashboard, demo IDs, and manual forms also work during local development without a Gemini key.

## Run Flutter

Use Flutter 3.38.5 or a compatible newer version.

```bash
cd app
flutter pub get
flutter run
```

The Android emulator defaults to `http://10.0.2.2:8000`. The iOS simulator defaults to `http://127.0.0.1:8000`. For a physical device or a hosted backend, pass the reachable URL through `--dart-define=API_BASE_URL=https://your-backend`. For a local web preview, run `flutter run -d chrome --web-port=8080` and include its origin in the backend's `WEB_ORIGINS`.

Tap **Nagarik AI** in the center of the bottom navigation to start Nepali speech recognition. Tap the text field for Nepali or English input. The assistant reads spoken replies using an installed Nepali voice. After reading a diagnostic question, it reopens the microphone for a spoken reply. **Ward Office Helpdesk** accepts the same inputs.

Document commands open fictional IDs. Complaint and HIB forms mark AI-prefilled fields as drafts and require a tap to create a local demo receipt. The social service forms validate sample input locally.

The supplied logo is preserved in `app/branding/nagarik-ai.svg`. Flutter displays a PNG render of its masked artwork. The demo uses a fictional portrait.

## Ward Office reference

`backend/reference/ward_office_kb.pdf` is the supplied v2.0 PDF. The backend checks its pinned SHA-256 digest and uploads the approved bytes to Gemini at startup. It places the PDF first in each model request and checks citations against the relevant service subsection. Gemini manages implicit cache use.

The backend blocks guidance when its reference is missing, modified, or symlinked. At deployment, mount the approved PDF read-only and give the service user read access to the PDF and its directory. `WARD_KB_PATH` can point to a regular file containing the same approved bytes. A new approved reference requires updating the pinned digest and its section boundaries.

## Tests

```bash
python -m unittest discover -s backend/tests
cd app
flutter test
flutter analyze
```
