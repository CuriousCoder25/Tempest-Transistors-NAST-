import asyncio
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import errors, types
from pydantic import ValidationError

from .assistant import WardAssistant
from .knowledge import DEFAULT_WARD_PDF, KnowledgeIntegrityError, read_verified_pdf
from .schemas import AssistantRequest, AssistantResponse
from .sessions import SessionCapacityReached, SessionStore

logger = logging.getLogger(__name__)
UNAVAILABLE = "सहायक अहिले उपलब्ध छैन। कृपया केही बेरपछि फेरि प्रयास गर्नुहोस्।"


@asynccontextmanager
async def lifespan(app: FastAPI):
    pdf = Path(os.environ.get("WARD_KB_PATH", DEFAULT_WARD_PDF))
    app.state.pdf = pdf
    app.state.assistant = None
    app.state.sessions = SessionStore()
    assistant = None
    try:
        content = await asyncio.to_thread(read_verified_pdf, pdf)
        if os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"):
            assistant = WardAssistant(genai.Client(), content)
            async with asyncio.timeout(110):
                await assistant.prepare()
            app.state.assistant = assistant
            app.state.status = "ready"
        else:
            app.state.status = "missing_gemini_key"
    except KnowledgeIntegrityError as exc:
        app.state.status = exc.status
        logger.error("Ward Office reference check failed (%s)", exc.status)
    except Exception as exc:
        app.state.status = "assistant_unavailable"
        logger.error("Assistant startup failed (%s)", type(exc).__name__)
    try:
        yield
    finally:
        if assistant is not None:
            await assistant.close()


app = FastAPI(title="Nagarik Sathi", version="0.1.0", lifespan=lifespan)
origins = [value.strip() for value in os.environ.get("WEB_ORIGINS", "").split(",") if value.strip()]
if origins:
    app.add_middleware(
        CORSMiddleware, allow_origins=origins,
        allow_methods=["POST", "GET"], allow_headers=["Content-Type"],
    )


@app.get("/health")
async def health(request: Request) -> dict[str, str]:
    try:
        await asyncio.to_thread(read_verified_pdf, request.app.state.pdf)
    except KnowledgeIntegrityError as exc:
        return {"assistant": exc.status}
    return {"assistant": request.app.state.status}


@app.post("/assistant", response_model=AssistantResponse)
async def ask(body: AssistantRequest, request: Request) -> AssistantResponse:
    assistant = request.app.state.assistant
    if assistant is None:
        raise HTTPException(status_code=503, detail=UNAVAILABLE)
    sessions: SessionStore = request.app.state.sessions
    try:
        session = sessions.acquire(body.session_id)
    except SessionCapacityReached as exc:
        raise HTTPException(status_code=503, detail=UNAVAILABLE) from exc
    question = types.Content(role="user", parts=[types.Part.from_text(text=body.message)])
    try:
        async with session.lock:
            await asyncio.to_thread(read_verified_pdf, request.app.state.pdf)
            async with asyncio.timeout(35):
                response = await assistant.respond(question, session.history)
            await asyncio.to_thread(read_verified_pdf, request.app.state.pdf)
            session.record(question, response.model_dump_json())
            return response
    except KnowledgeIntegrityError as exc:
        logger.error("Ward Office reference check failed (%s)", exc.status)
        raise HTTPException(status_code=503, detail=UNAVAILABLE) from exc
    except (errors.APIError, ValidationError, TimeoutError, RuntimeError) as exc:
        logger.warning("Assistant turn failed (%s)", type(exc).__name__)
        raise HTTPException(status_code=502, detail=UNAVAILABLE) from exc
    finally:
        sessions.release(session)
