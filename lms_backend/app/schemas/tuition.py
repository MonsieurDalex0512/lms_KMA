from pydantic import BaseModel
from typing import Optional

class TuitionSettings(BaseModel):
    price_per_credit: int

class TuitionBase(BaseModel):
    semester: str
    total_amount: int
    paid_amount: int
    status: str

class TuitionUpdate(BaseModel):
    paid_amount: Optional[int] = None
    status: Optional[str] = None

class TuitionResponse(TuitionBase):
    id: int
    student_id: int
    
    student_name: Optional[str] = None
    student_code: Optional[str] = None

    class Config:
        from_attributes = True
