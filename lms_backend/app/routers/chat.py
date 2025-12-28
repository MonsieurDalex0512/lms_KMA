from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.dependencies import get_current_user
from app.models import ChatGroup, ChatMessage, ChatGroupMember, User, Class, Enrollment
from app.schemas.chat import (
    ChatGroupCreate, ChatGroupResponse, ChatMessageResponse,
    ChatGroupMemberResponse, AddMembersRequest
)
from typing import List
from sqlalchemy import desc

router = APIRouter(prefix="/chat", tags=["chat"])

@router.post("/groups", response_model=ChatGroupResponse)
def create_chat_group(
    group_data: ChatGroupCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role.value != "lecturer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lecturers can create chat groups"
        )
    
    class_obj = db.query(Class).filter(Class.id == group_data.class_id).first()
    if not class_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Class not found"
        )
    
    if class_obj.lecturer_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only create chat groups for your own classes"
        )
    
    existing_group = db.query(ChatGroup).filter(
        ChatGroup.class_id == group_data.class_id
    ).first()
    
    if existing_group:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chat group already exists for this class"
        )
    
    chat_group = ChatGroup(
        name=group_data.name,
        class_id=group_data.class_id,
        created_by=current_user.id
    )
    db.add(chat_group)
    db.commit()
    db.refresh(chat_group)
    
    lecturer_member = ChatGroupMember(
        group_id=chat_group.id,
        user_id=current_user.id
    )
    db.add(lecturer_member)
    
    enrollments = db.query(Enrollment).filter(
        Enrollment.class_id == group_data.class_id
    ).all()
    
    for enrollment in enrollments:
        member = ChatGroupMember(
            group_id=chat_group.id,
            user_id=enrollment.student_id
        )
        db.add(member)
    
    db.commit()
    
    member_count = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == chat_group.id
    ).count()
    
    response = ChatGroupResponse(
        id=chat_group.id,
        name=chat_group.name,
        class_id=chat_group.class_id,
        created_by=chat_group.created_by,
        created_at=chat_group.created_at,
        member_count=member_count
    )
    
    return response

@router.get("/groups", response_model=List[ChatGroupResponse])
def get_chat_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    memberships = db.query(ChatGroupMember).filter(
        ChatGroupMember.user_id == current_user.id
    ).all()
    
    group_ids = [m.group_id for m in memberships]
    
    groups = db.query(ChatGroup).filter(ChatGroup.id.in_(group_ids)).all()
    
    response = []
    for group in groups:
        member_count = db.query(ChatGroupMember).filter(
            ChatGroupMember.group_id == group.id
        ).count()
        
        response.append(ChatGroupResponse(
            id=group.id,
            name=group.name,
            class_id=group.class_id,
            created_by=group.created_by,
            created_at=group.created_at,
            member_count=member_count
        ))
    
    return response

@router.get("/groups/{group_id}/messages", response_model=List[ChatMessageResponse])
def get_group_messages(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    member = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == group_id,
        ChatGroupMember.user_id == current_user.id
    ).first()
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this group"
        )
    
    messages = db.query(ChatMessage).filter(
        ChatMessage.group_id == group_id
    ).order_by(desc(ChatMessage.timestamp)).limit(100).all()
    
    messages.reverse()
    
    response = []
    for msg in messages:
        sender = db.query(User).filter(User.id == msg.sender_id).first()
        response.append(ChatMessageResponse(
            id=msg.id,
            group_id=msg.group_id,
            sender_id=msg.sender_id,
            sender_name=sender.full_name if sender else "Unknown",
            encrypted_content=msg.encrypted_content,
            timestamp=msg.timestamp
        ))
    
    return response

@router.get("/groups/{group_id}/members", response_model=List[ChatGroupMemberResponse])
def get_group_members(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    member = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == group_id,
        ChatGroupMember.user_id == current_user.id
    ).first()
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this group"
        )
    
    members = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == group_id
    ).all()
    
    response = []
    for m in members:
        user = db.query(User).filter(User.id == m.user_id).first()
        if user:
            response.append(ChatGroupMemberResponse(
                user_id=user.id,
                full_name=user.full_name,
                role=user.role.value,
                joined_at=m.joined_at
            ))
    
    return response

@router.post("/groups/{group_id}/members")
def add_group_members(
    group_id: int,
    request: AddMembersRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role.value != "lecturer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lecturers can add members"
        )
    
    group = db.query(ChatGroup).filter(ChatGroup.id == group_id).first()
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )
    
    if group.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group creator can add members"
        )
    
    added_count = 0
    for user_id in request.user_ids:
        existing = db.query(ChatGroupMember).filter(
            ChatGroupMember.group_id == group_id,
            ChatGroupMember.user_id == user_id
        ).first()
        
        if not existing:
            member = ChatGroupMember(
                group_id=group_id,
                user_id=user_id
            )
            db.add(member)
            added_count += 1
    
    db.commit()
    
    return {"success": True, "added_count": added_count}

@router.delete("/groups/{group_id}/members/{user_id}")
def remove_group_member(
    group_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role.value != "lecturer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lecturers can remove members"
        )
    
    group = db.query(ChatGroup).filter(ChatGroup.id == group_id).first()
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )
    
    if group.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group creator can remove members"
        )
    
    member = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == group_id,
        ChatGroupMember.user_id == user_id
    ).first()
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Member not found in this group"
        )
    
    db.delete(member)
    db.commit()
    
    return {"success": True}
