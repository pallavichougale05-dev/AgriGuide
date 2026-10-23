"""
AgriGuide Authentication API
"""

import base64
import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from database import get_db
from models.user import User


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)

security = HTTPBearer()

JWT_ALGORITHM = "HS256"

JWT_SECRET = os.getenv(
    "AGRIGUIDE_AUTH_SECRET",
)

if not JWT_SECRET:
    raise RuntimeError(
        "AGRIGUIDE_AUTH_SECRET environment variable is not set."
    )


class RegisterRequest(BaseModel):
    full_name: str = Field(
        min_length=2,
        max_length=150,
    )

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )


class LoginRequest(BaseModel):
    email: EmailStr

    password: str = Field(
        min_length=1,
        max_length=128,
    )


class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    success: bool
    message: str
    access_token: str
    token_type: str
    user: UserResponse


def hash_password(password: str) -> tuple[str, str]:
    """
    Creates a unique salt and derives a password hash.
    The plain password is never stored in PostgreSQL.
    """

    salt = secrets.token_bytes(16)

    password_hash = hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=32768,
        r=8,
        p=1,
        dklen=64,
        maxmem=64 * 1024 * 1024,
    )

    salt_text = base64.b64encode(
        salt,
    ).decode("utf-8")

    hash_text = base64.b64encode(
        password_hash,
    ).decode("utf-8")

    return hash_text, salt_text


def verify_password(
    password: str,
    stored_hash: str,
    stored_salt: str,
) -> bool:
    try:
        salt = base64.b64decode(
            stored_salt.encode("utf-8"),
        )

        expected_hash = base64.b64decode(
            stored_hash.encode("utf-8"),
        )

        actual_hash = hashlib.scrypt(
            password.encode("utf-8"),
            salt=salt,
            n=32768,
            r=8,
            p=1,
            dklen=64,
            maxmem=64 * 1024 * 1024,
        )

        return hmac.compare_digest(
            actual_hash,
            expected_hash,
        )

    except Exception:
        return False


def create_access_token(
    user: User,
) -> str:
    expires_at = (
        datetime.now(timezone.utc)
        + timedelta(days=7)
    )

    payload = {
        "sub": str(user.id),
        "email": user.email,
        "name": user.full_name,
        "exp": expires_at,
    }

    return jwt.encode(
        payload,
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials =
        Depends(security),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
        )

        user_id = payload.get("sub")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token.",
                headers={
                    "WWW-Authenticate": "Bearer",
                },
            )

        user = db.get(
            User,
            int(user_id),
        )

        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account not found or inactive.",
                headers={
                    "WWW-Authenticate": "Bearer",
                },
            )

        return user

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your login session has expired. Please log in again.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )


@router.post(
    "/register",
    response_model=AuthResponse,
)
def register_user(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    email = data.email.strip().lower()
    full_name = data.full_name.strip()

    if len(full_name) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please enter a valid full name.",
        )

    existing_user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    password_hash, password_salt = hash_password(
        data.password,
    )

    user = User(
        full_name=full_name,
        email=email,
        password_hash=password_hash,
        password_salt=password_salt,
        is_active=True,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(
        user,
    )

    return AuthResponse(
        success=True,
        message="Account created successfully.",
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
        ),
    )


@router.post(
    "/login",
    response_model=AuthResponse,
)
def login_user(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    email = data.email.strip().lower()

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is currently inactive.",
        )

    password_valid = verify_password(
        data.password,
        user.password_hash,
        user.password_salt,
    )

    if not password_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    access_token = create_access_token(
        user,
    )

    return AuthResponse(
        success=True,
        message="Login successful.",
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
        ),
    )


@router.get(
    "/me",
    response_model=UserResponse,
)
def get_my_profile(
    current_user: User = Depends(
        get_current_user,
    ),
):
    return UserResponse(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
    )