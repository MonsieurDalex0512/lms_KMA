from datetime import timedelta
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status, Form
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.auth.security import create_access_token, verify_password, get_password_hash
from app.auth.dependencies import get_current_active_user
from app.core.config import settings
from app.crud.user import create_user, get_user_by_username, get_user_by_email
from app.database import get_db
from app.schemas.user import Token, UserCreate, User, PasswordChange
from app.models.enums import UserRole
from app.services.otp_service import generate_otp, store_otp, verify_otp, send_otp_email

router = APIRouter(prefix="/auth", tags=["auth"])

pending_dean_logins = {}

class OTPVerifyRequest(BaseModel):
    username: str
    otp: str

class OTPResponse(BaseModel):
    requires_otp: bool
    message: str
    email_hint: Optional[str] = None

@router.post("/register", response_model=User)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    db_email = get_user_by_email(db, email=user.email)
    if db_email:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    return create_user(db=db, user=user)

@router.post("/login")
async def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db)
):
    user = get_user_by_username(db, username=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if user.role == UserRole.DEAN:
        otp = generate_otp()
        store_otp(user.id, otp)
        
        email = user.email
        full_name = user.full_name or user.username
        
        email_sent = send_otp_email(email, otp, full_name)
        
        if not email_sent:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send OTP email. Please try again."
            )
        
        pending_dean_logins[user.username] = {
            "user_id": user.id,
            "username": user.username,
            "role": user.role.value
        }
        
        email_parts = email.split('@')
        masked_email = email_parts[0][:3] + '***@' + email_parts[1] if len(email_parts) == 2 else '***'
        
        return {
            "requires_otp": True,
            "message": f"OTP đã được gửi đến email của bạn. Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.",
            "email_hint": masked_email
        }
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "role": user.role.value}


@router.post("/verify-otp", response_model=Token)
async def verify_otp_login(
    request: OTPVerifyRequest,
    db: Session = Depends(get_db)
):
    """Verify OTP for Dean login"""
    username = request.username
    otp = request.otp
    
    if username not in pending_dean_logins:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phiên xác thực đã hết hạn. Vui lòng thử lại từ đầu."
        )
    
    pending = pending_dean_logins[username]
    user_id = pending["user_id"]
    
    success, remaining = verify_otp(user_id, otp)
    
    if not success:
        if remaining <= 0:
            del pending_dean_logins[username]
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Đã hết số lần thử. Vui lòng đăng nhập lại."
            )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Mã OTP không đúng. Còn {remaining} lần thử."
        )
    
    del pending_dean_logins[username]
    
    user = get_user_by_username(db, username=username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer", "role": user.role.value}


@router.post("/resend-otp")
async def resend_otp(
    username: str = Form(...),
    db: Session = Depends(get_db)
):
    """Resend OTP for Dean login"""
    user = get_user_by_username(db, username=username)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRole.DEAN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP is only required for Dean users"
        )
    
    otp = generate_otp()
    store_otp(user.id, otp)
    
    email = user.email
    full_name = user.full_name or user.username
    email_sent = send_otp_email(email, otp, full_name)
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send OTP email. Please try again."
        )
    
    pending_dean_logins[user.username] = {
        "user_id": user.id,
        "username": user.username,
        "role": user.role.value
    }
    
    return {
        "message": f"OTP mới đã được gửi. Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút."
    }


@router.post("/change-password")
def change_password(
    old_password: str = Form(...),
    new_password: str = Form(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if not verify_password(old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Old password is incorrect"
        )
    
    current_user.hashed_password = get_password_hash(new_password)
    db.commit()
    
    return {"message": "Password changed successfully"}
