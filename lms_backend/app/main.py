from fastapi import FastAPI, Request
from app.database import engine, Base
from app.models import (
    User, Student, Lecturer, Department, Course,
    Class, Schedule, Enrollment, Grade,
    AcademicYear, Semester, AcademicResult, CumulativeResult, Report, Tuition, Setting
)

app = FastAPI(title="LMS Backend")

from fastapi.middleware.cors import CORSMiddleware

origins = [
    "http://localhost:5173",
    "http://localhost",              
    "http://127.0.0.1",
    "https://lms-system-nu-one.vercel.app", 
    "*"                               
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,         
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],            
    expose_headers=["*"],           
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    # body = await request.body()
    # print(f"REQUEST: {request.method} {request.url}")
    # print(f"HEADERS: {request.headers}")
    # print(f"BODY: {body.decode(errors='ignore')}")
    response = await call_next(request)
    return response

from app.routers import auth, students, lecturers, deans, statistics, reports, tuitions, search

app.include_router(auth.router)
app.include_router(students.router)
app.include_router(lecturers.router)
app.include_router(deans.router)
app.include_router(statistics.router)
app.include_router(reports.router)
app.include_router(tuitions.router)
app.include_router(search.router)

@app.on_event("startup")
async def startup():
    Base.metadata.create_all(bind=engine)
    print("All tables created/verified")

@app.get("/")
def read_root():
    return {"message": "Welcome to LMS Backend"}
