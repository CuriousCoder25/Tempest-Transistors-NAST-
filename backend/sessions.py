import asyncio
import time
from dataclasses import dataclass, field
from uuid import UUID

from google.genai import types

SESSION_TTL_SECONDS = 30 * 60
MAX_SESSIONS = 256
MAX_TURNS = 12


class SessionCapacityReached(Exception):
    pass


@dataclass
class Session:
    history: list[types.Content] = field(default_factory=list)
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)
    touched: float = field(default_factory=time.monotonic)
    users: int = 0

    def record(self, question: types.Content, answer: str) -> None:
        self.history.extend([
            question,
            types.Content(role="model", parts=[types.Part.from_text(text=answer)]),
        ])
        del self.history[:-2 * MAX_TURNS]


class SessionStore:
    def __init__(self) -> None:
        self._sessions: dict[UUID, Session] = {}

    def acquire(self, session_id: UUID) -> Session:
        now = time.monotonic()
        expired = [
            key for key, session in self._sessions.items()
            if not session.users and now - session.touched >= SESSION_TTL_SECONDS
        ]
        for key in expired:
            del self._sessions[key]
        session = self._sessions.get(session_id)
        if session is None:
            if len(self._sessions) >= MAX_SESSIONS:
                raise SessionCapacityReached
            session = self._sessions[session_id] = Session()
        session.users += 1
        return session

    def release(self, session: Session) -> None:
        session.users -= 1
        session.touched = time.monotonic()
