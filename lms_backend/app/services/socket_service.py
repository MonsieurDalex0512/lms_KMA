import socketio
from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import ChatGroup, ChatMessage, ChatGroupMember, User
from app.auth.security import decode_access_token
from datetime import datetime
from typing import Dict

sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',
    logger=True,
    engineio_logger=True
)

connected_users: Dict[str, int] = {}

@sio.event
async def connect(sid, environ, auth):
    try:
        if not auth or 'token' not in auth:
            return False
        
        token = auth['token']
        payload = decode_access_token(token)
        
        if not payload:
            return False
        
        user_id = payload.get('user_id')
        if not user_id:
            return False
        
        connected_users[sid] = int(user_id)
        print(f"User {user_id} connected with sid {sid}")
        return True
        
    except Exception as e:
        print(f"Connection error: {e}")
        return False

@sio.event
async def disconnect(sid):
    if sid in connected_users:
        user_id = connected_users[sid]
        del connected_users[sid]
        print(f"User {user_id} disconnected")

@sio.event
async def join_group(sid, data):
    try:
        group_id = data.get('group_id')
        user_id = connected_users.get(sid)
        
        print(f"join_group event received: sid={sid}, group_id={group_id}, user_id={user_id}")
        
        if not user_id or not group_id:
            print(f"join_group failed: missing user_id or group_id")
            return {'success': False, 'error': 'Invalid data'}
        
        room_name = f"group_{group_id}"
        await sio.enter_room(sid, room_name)
        
        print(f"User {user_id} joined group {group_id} (room: {room_name})")
        return {'success': True}
        
    except Exception as e:
        print(f"Join group error: {e}")
        return {'success': False, 'error': str(e)}

@sio.event
async def leave_group(sid, data):
    try:
        group_id = data.get('group_id')
        user_id = connected_users.get(sid)
        
        if not user_id or not group_id:
            return {'success': False, 'error': 'Invalid data'}
        
        room_name = f"group_{group_id}"
        await sio.leave_room(sid, room_name)
        
        print(f"User {user_id} left group {group_id}")
        return {'success': True}
        
    except Exception as e:
        print(f"Leave group error: {e}")
        return {'success': False, 'error': str(e)}

@sio.event
async def send_message(sid, data):
    try:
        group_id = data.get('group_id')
        encrypted_content = data.get('encrypted_content')
        user_id = connected_users.get(sid)
        
        if not user_id or not group_id or not encrypted_content:
            return {'success': False, 'error': 'Invalid data'}
        
        from app.database import SessionLocal
        db = SessionLocal()
        
        try:
            member = db.query(ChatGroupMember).filter(
                ChatGroupMember.group_id == group_id,
                ChatGroupMember.user_id == user_id
            ).first()
            
            if not member:
                return {'success': False, 'error': 'Not a member of this group'}
            
            message = ChatMessage(
                group_id=group_id,
                sender_id=user_id,
                encrypted_content=encrypted_content
            )
            db.add(message)
            db.commit()
            db.refresh(message)
            
            message_count = db.query(ChatMessage).filter(
                ChatMessage.group_id == group_id
            ).count()
            
            if message_count > 100:
                oldest_messages = db.query(ChatMessage).filter(
                    ChatMessage.group_id == group_id
                ).order_by(ChatMessage.timestamp.asc()).limit(message_count - 100).all()
                
                for old_msg in oldest_messages:
                    db.delete(old_msg)
                db.commit()
            
            user = db.query(User).filter(User.id == user_id).first()
            
            message_data = {
                'id': message.id,
                'group_id': message.group_id,
                'sender_id': message.sender_id,
                'sender_name': user.full_name if user else 'Unknown',
                'encrypted_content': message.encrypted_content,
                'timestamp': message.timestamp.isoformat()
            }
            
            room_name = f"group_{group_id}"
            
            # Debug: Check who is in the room
            # Note: sio.manager.rooms is an internal structure, but useful for debug
            # Structure: namespace -> room -> sids
            try:
                # This access pattern depends on the socketio implementation (AsyncServer)
                # For debugging purposes only
                print(f"Emitting to room {room_name}")
            except Exception as e:
                print(f"Debug room error: {e}")

            # Force emit to sender directly to verify downstream connection
            print(f"Force emitting to sender {sid}")
            await sio.emit('new_message', message_data, to=sid)
            
            # Broadcast to room
            print(f"Broadcasting to room {room_name}")
            await sio.emit('new_message', message_data, room=room_name, skip_sid=sid) # Skip sender since we emitted directly above

            return {'success': True, 'message': message_data}
            
        finally:
            db.close()
        
    except Exception as e:
        print(f"Send message error: {e}")
        return {'success': False, 'error': str(e)}

socket_app = socketio.ASGIApp(sio)
