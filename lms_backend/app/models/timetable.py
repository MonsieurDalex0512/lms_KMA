from sqlalchemy import Column, Integer, String, ForeignKey, Date, Boolean
from sqlalchemy.orm import relationship
from app.database import Base

class Timetable(Base):
    __tablename__ = "timetables"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"))
    date = Column(Date, nullable=False)
    start_period = Column(Integer)
    end_period = Column(Integer)
    room = Column(String)
    is_makeup = Column(Boolean, default=False) 
    note = Column(String, nullable=True)

    class_ = relationship("Class", back_populates="timetables")
