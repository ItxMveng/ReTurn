from pydantic import BaseModel


class FirebaseTokenRequest(BaseModel):
    firebase_token: str


class OTPRequest(BaseModel):
    phone_number: str


class OTPVerify(BaseModel):
    phone_number: str
    otp_code: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str = ""
    token_type: str = "bearer"
    is_new_user: bool = False


class RefreshRequest(BaseModel):
    refresh_token: str
