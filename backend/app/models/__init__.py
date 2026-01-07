"""SQLModel database models."""

from app.models.exercise import (
    BodyPart,
    Exercise,
    ExerciseCategory,
    ExerciseCreate,
    ExerciseRead,
    ExerciseUpdate,
)
from app.models.exercise_video import (
    ExerciseVideo,
    ExerciseVideoCreate,
    ExerciseVideoRead,
    ExerciseVideoUpdate,
)
from app.models.session import (
    Session,
    SessionComplete,
    SessionCreate,
    SessionExerciseResult,
    SessionExerciseResultCreate,
    SessionExerciseResultRead,
    SessionRead,
    SessionReadWithResults,
    SessionStart,
    SessionStatus,
    SessionSummary,
)
from app.models.user import (
    EmailVerification,
    ForgotPassword,
    PasswordReset,
    Token,
    TokenPayload,
    User,
    UserCreate,
    UserLogin,
    UserRead,
    UserRole,
    UserUpdate,
)

__all__ = [
    # User
    "User",
    "UserCreate",
    "UserLogin",
    "UserRead",
    "UserRole",
    "UserUpdate",
    "Token",
    "TokenPayload",
    "PasswordReset",
    "EmailVerification",
    "ForgotPassword",
    # Exercise
    "Exercise",
    "ExerciseCreate",
    "ExerciseRead",
    "ExerciseUpdate",
    "ExerciseCategory",
    "BodyPart",
    # Exercise Video
    "ExerciseVideo",
    "ExerciseVideoCreate",
    "ExerciseVideoRead",
    "ExerciseVideoUpdate",
    # Session
    "Session",
    "SessionCreate",
    "SessionStart",
    "SessionComplete",
    "SessionRead",
    "SessionReadWithResults",
    "SessionStatus",
    "SessionExerciseResult",
    "SessionExerciseResultCreate",
    "SessionExerciseResultRead",
    "SessionSummary",
]
