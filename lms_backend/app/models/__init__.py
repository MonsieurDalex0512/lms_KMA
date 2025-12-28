from app.models.user import User, Student, Lecturer
from app.models.academic import Department, Course, Class, Schedule, Enrollment, Grade
from app.models.academic_year import AcademicYear, Semester, AcademicResult
from app.models.cumulative_result import CumulativeResult
from app.models.timetable import Timetable
from app.models.audit_log import AuditLog
from app.models.enums import UserRole
from app.models.report import Report
from app.models.tuition import Tuition
from app.models.setting import Setting
from app.models.chat import ChatGroup, ChatMessage, ChatGroupMember
