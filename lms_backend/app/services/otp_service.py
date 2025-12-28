import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from typing import Optional, Dict
from app.core.config import settings

# In-memory OTP storage (for production, use Redis or database)
otp_storage: Dict[str, dict] = {}

def generate_otp() -> str:
    """Generate a random OTP code"""
    return ''.join(random.choices(string.digits, k=settings.OTP_LENGTH))

def store_otp(user_id: int, otp: str) -> None:
    """Store OTP with expiration time"""
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }

def verify_otp(user_id: int, otp: str) -> tuple[bool, int]:
    """Verify OTP for a user. Returns (success, remaining_attempts)"""
    user_key = str(user_id)
    max_attempts = 10
    
    if user_key not in otp_storage:
        return (False, 0)
    
    stored = otp_storage[user_key]
    
    # Check expiration
    if datetime.utcnow() > stored["expires_at"]:
        del otp_storage[user_key]
        return (False, 0)
    
    # Check attempts (max 10)
    if stored["attempts"] >= max_attempts:
        del otp_storage[user_key]
        return (False, 0)
    
    # Increment attempts
    stored["attempts"] += 1
    remaining = max_attempts - stored["attempts"]
    
    # Verify OTP
    if stored["otp"] == otp:
        del otp_storage[user_key]  # Clear after successful verification
        return (True, remaining)
    
    # If no more attempts left, delete
    if remaining <= 0:
        del otp_storage[user_key]
    
    return (False, remaining)

def clear_otp(user_id: int) -> None:
    """Clear OTP for a user"""
    user_key = str(user_id)
    if user_key in otp_storage:
        del otp_storage[user_key]

def send_otp_email(email: str, otp: str, full_name: str) -> bool:
    """Send OTP via email using Gmail SMTP"""
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'LMS - Mã xác thực đăng nhập (OTP)'
        msg['From'] = settings.SMTP_EMAIL
        msg['To'] = email
        
        # HTML email content
        html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .otp-code {{ font-size: 32px; font-weight: bold; color: #667eea; text-align: center; padding: 20px; background: white; border-radius: 10px; margin: 20px 0; letter-spacing: 8px; }}
                .warning {{ color: #e74c3c; font-size: 12px; margin-top: 20px; }}
                .footer {{ text-align: center; color: #888; font-size: 12px; margin-top: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Xác thực đăng nhập</h1>
                </div>
                <div class="content">
                    <p>Xin chào <strong>{full_name}</strong>,</p>
                    <p>Bạn đang đăng nhập vào hệ thống LMS với vai trò Trưởng Khoa. Vui lòng sử dụng mã OTP sau để hoàn tất đăng nhập:</p>
                    
                    <div class="otp-code">{otp}</div>
                    
                    <p>⏱️ Mã này có hiệu lực trong <strong>{settings.OTP_EXPIRE_MINUTES} phút</strong>.</p>
                    
                    <p class="warning">
                        ⚠️ Không chia sẻ mã này với bất kỳ ai. Nhân viên LMS sẽ không bao giờ yêu cầu bạn cung cấp mã OTP.
                    </p>
                </div>
                <div class="footer">
                    <p>© 2024 LMS System. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        text = f"""
        Xin chào {full_name},
        
        Mã OTP của bạn là: {otp}
        
        Mã này có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.
        
        Không chia sẻ mã này với bất kỳ ai.
        """
        
        part1 = MIMEText(text, 'plain')
        part2 = MIMEText(html, 'html')
        msg.attach(part1)
        msg.attach(part2)
        
        # Send email
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
        
        print(f"OTP email sent successfully to {email}")
        return True
        
    except Exception as e:
        print(f"Failed to send OTP email: {e}")
        return False
