import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Search, TrendingUp, Award } from 'lucide-react';

interface Student {
    id: number;
    student_code: string;
    full_name: string;
}

interface SemesterResult {
    semester_id: number;
    semester_code: string;
    semester_name: string;
    gpa: number;
    total_credits: number;
    completed_credits: number;
    failed_credits: number;
}

interface StudentResults {
    student_id: number;
    student_code: string;
    full_name: string;
    semester_results: SemesterResult[];
    cumulative_cpa: number;
    total_registered_credits: number;
    total_completed_credits: number;
    total_failed_credits: number;
}

const DeanAcademicResults: React.FC = () => {
    const [students, setStudents] = useState<Student[]>([]);
    const [selectedStudent, setSelectedStudent] = useState<number | null>(null);
    const [studentResults, setStudentResults] = useState<StudentResults | null>(null);
    const [loading, setLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchStudents();
    }, []);

    const fetchStudents = async () => {
        try {
            const res = await api.get('/deans/students');
            setStudents(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    const fetchStudentResults = async (studentId: number) => {
        setLoading(true);
        try {
            const res = await api.get(`/deans/students/${studentId}/academic-results`);
            setStudentResults(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleStudentSelect = (studentId: number) => {
        setSelectedStudent(studentId);
        fetchStudentResults(studentId);
    };

    const filteredStudents = students.filter(s =>
        s.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.student_code.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Kết Quả Học Tập</h2>
                    <p className="text-gray-500 text-sm">Xem kết quả học tập theo sinh viên</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Danh sách sinh viên */}
                <div className="lg:col-span-1">
                    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
                        <div className="mb-4">
                            <div className="bg-white p-3 rounded-xl border border-gray-200 flex items-center gap-3">
                                <Search className="h-5 w-5 text-gray-400" />
                                <input
                                    type="text"
                                    placeholder="Tìm sinh viên..."
                                    className="flex-1 outline-none text-gray-700 bg-transparent"
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                />
                            </div>
                        </div>

                        <div className="space-y-2 max-h-[600px] overflow-y-auto">
                            {filteredStudents.map(student => (
                                <button
                                    key={student.id}
                                    onClick={() => handleStudentSelect(student.id)}
                                    className={`w-full text-left p-3 rounded-xl transition-all ${selectedStudent === student.id
                                            ? 'bg-blue-50 border-2 border-blue-500'
                                            : 'bg-gray-50 hover:bg-gray-100 border-2 border-transparent'
                                        }`}
                                >
                                    <div className="font-bold text-gray-900">{student.full_name}</div>
                                    <div className="text-xs text-blue-600">{student.student_code}</div>
                                </button>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Kết quả học tập */}
                <div className="lg:col-span-2">
                    {loading ? (
                        <div className="flex justify-center p-12 bg-white rounded-2xl">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                        </div>
                    ) : studentResults ? (
                        <div className="space-y-6">
                            {/* Tổng quan CPA */}
                            <div className="bg-gradient-to-br from-blue-500 to-blue-600 p-6 rounded-2xl text-white shadow-lg">
                                <div className="flex items-center gap-3 mb-4">
                                    <Award className="h-8 w-8" />
                                    <div>
                                        <div className="text-sm opacity-90">CPA Tích Lũy Toàn Khóa</div>
                                        <div className="text-4xl font-bold">{studentResults.cumulative_cpa.toFixed(2)}</div>
                                    </div>
                                </div>
                                <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t border-white/20">
                                    <div>
                                        <div className="text-xs opacity-75">Tổng TC</div>
                                        <div className="text-lg font-bold">{studentResults.total_registered_credits}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs opacity-75">TC Đạt</div>
                                        <div className="text-lg font-bold">{studentResults.total_completed_credits}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs opacity-75">TC Trượt</div>
                                        <div className="text-lg font-bold">{studentResults.total_failed_credits}</div>
                                    </div>
                                </div>
                            </div>

                            {/* GPA theo từng kỳ */}
                            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                                <div className="p-4 bg-gray-50 border-b">
                                    <h3 className="font-bold text-gray-900 flex items-center gap-2">
                                        <TrendingUp className="h-5 w-5 text-blue-600" />
                                        GPA Từng Học Kỳ
                                    </h3>
                                </div>
                                <table className="w-full text-left text-sm text-gray-600">
                                    <thead className="bg-gray-50/50 text-gray-800 font-semibold uppercase text-xs">
                                        <tr>
                                            <th className="px-6 py-4">Học Kỳ</th>
                                            <th className="px-6 py-4 text-center">GPA</th>
                                            <th className="px-6 py-4 text-center">TC Đạt</th>
                                            <th className="px-6 py-4 text-center">TC Trượt</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {studentResults.semester_results.map(sem => (
                                            <tr key={sem.semester_id} className="hover:bg-blue-50/50 transition-colors">
                                                <td className="px-6 py-4">
                                                    <div className="font-bold text-gray-900">{sem.semester_name}</div>
                                                    <div className="text-xs text-gray-500">{sem.semester_code}</div>
                                                </td>
                                                <td className="px-6 py-4 text-center">
                                                    <span className={`px-3 py-1 rounded-md font-bold ${sem.gpa >= 3.2 ? 'bg-green-100 text-green-700' :
                                                            sem.gpa >= 2.5 ? 'bg-blue-100 text-blue-700' :
                                                                'bg-yellow-100 text-yellow-700'
                                                        }`}>
                                                        {sem.gpa.toFixed(2)}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 text-center font-medium">
                                                    {sem.completed_credits}/{sem.total_credits}
                                                </td>
                                                <td className="px-6 py-4 text-center">
                                                    {sem.failed_credits > 0 ? (
                                                        <span className="text-red-600 font-bold">{sem.failed_credits}</span>
                                                    ) : (
                                                        <span className="text-gray-400">0</span>
                                                    )}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    ) : (
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-12 text-center">
                            <TrendingUp className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                            <p className="text-gray-400 italic">Chọn sinh viên để xem kết quả học tập</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default DeanAcademicResults;
