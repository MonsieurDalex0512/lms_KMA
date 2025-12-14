from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.models.user import User, UserRole
from app.auth.dependencies import get_current_user, get_current_active_user
from app.services.tuition_service import tuition_service
from app.schemas.tuition import TuitionResponse, TuitionUpdate, TuitionSettings

router = APIRouter(
    tags=["tuitions"]
)

@router.get("/students/me/tuitions", response_model=List[TuitionResponse])
def get_my_tuitions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can view own tuition")
    
    return tuition_service.get_student_tuitions(db, current_user.id)

@router.get("/deans/tuitions", response_model=List[TuitionResponse])
def get_all_tuitions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    tuitions = tuition_service.get_all_tuitions(db, skip=skip, limit=limit)
    
    return tuitions

@router.put("/deans/tuitions/{tuition_id}", response_model=TuitionResponse)
def update_tuition_payment(
    tuition_id: int,
    tuition_in: TuitionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    tuition = tuition_service.update_payment(db, tuition_id, tuition_in.paid_amount)
    if not tuition:
        raise HTTPException(status_code=404, detail="Tuition record not found")
        
    return tuition

@router.get("/deans/tuition-settings", response_model=TuitionSettings)
def get_tuition_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    price = tuition_service.get_current_price(db)
    return {"price_per_credit": price}

@router.post("/deans/tuition-settings", response_model=TuitionSettings)
def update_tuition_settings(
    settings: TuitionSettings,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    price = tuition_service.set_current_price(db, settings.price_per_credit)
    return {"price_per_credit": price}
