import re

from pydantic import BaseModel, field_validator

_PHONE_RE = re.compile(r"^\+?[0-9]{7,15}$")  # E.164, tout pays
_OTP_RE   = re.compile(r"^\d{6}$")


class FirebaseTokenRequest(BaseModel):
    firebase_token: str

    @field_validator("firebase_token")
    @classmethod
    def token_not_empty(cls, v: str) -> str:
        if len(v.strip()) < 10:
            raise ValueError("Token Firebase invalide.")
        return v.strip()


class OTPRequest(BaseModel):
    phone_number: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not _PHONE_RE.match(v):
            raise ValueError(
                "Numéro de téléphone invalide (format international, ex. +33612345678)."
            )
        return v


class OTPVerify(BaseModel):
    phone_number: str
    otp_code: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not _PHONE_RE.match(v):
            raise ValueError("Numéro de téléphone invalide.")
        return v

    @field_validator("otp_code")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        v = v.strip()
        if not _OTP_RE.match(v):
            raise ValueError("Le code OTP doit contenir exactement 6 chiffres.")
        return v


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str = ""
    token_type: str = "bearer"
    is_new_user: bool = False


class RefreshRequest(BaseModel):
    refresh_token: str

    @field_validator("refresh_token")
    @classmethod
    def token_not_empty(cls, v: str) -> str:
        if len(v.strip()) < 10:
            raise ValueError("Refresh token invalide.")
        return v.strip()
