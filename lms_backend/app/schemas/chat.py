from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

class ChatGroupCreate(BaseModel):
    name: str
    class_id: int

class ChatGroupResponse(BaseModel):
    id: int
    name: str
    class_id: int
    created_by: int
    created_at: datetime
    member_count: Optional[int] = 0

    class Config:
        from_attributes = True

class ChatMessageResponse(BaseModel):
    id: int
    group_id: int
    sender_id: int
    sender_name: str
    encrypted_content: str
    timestamp: datetime

    class Config:
        from_attributes = True

class ChatGroupMemberResponse(BaseModel):
    user_id: int
    full_name: str
    role: str
    joined_at: datetime

    class Config:
        from_attributes = True

class AddMembersRequest(BaseModel):
    user_ids: List[int]
