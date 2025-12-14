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
    const [recalculating, setRecalculating] = useState(false);

    useEffect(() => {
        fetchStudents();
    }, []);

    // Auto-refresh khi quay lại tab/window
    useEffect(() => {
        const handleVisibilityChange = () => {
            if (!document.hidden && selectedStudent) {
                // Refresh khi quay lại tab và đã chọn student
                fetchStudentResults(selectedStudent);
            }
        };

        const handleFocus = () => {
            if (selectedStudent) {
                fetchStudentResults(selectedStudent);
            }
        };

        window.addEventListener('visibilitychange', handleVisibilityChange);
        window.addEventListener('focus', handleFocus);

        return () => {
            window.removeEventListener('visibilitychange', handleVisibilityChange);
            window.removeEventListener('focus', handleFocus);
        };
    }, [selectedStudent]);

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

    const handleRecalculateAll = async () => {
        if (!confirm("Bạn có chắc muốn recalculate tất cả kết quả học tập? Điều này sẽ:\n- Xóa các semester không còn lớp học\n- Cập nhật lại GPA/CPA cho tất cả sinh viên\n\nQuá trình này có thể mất vài phút.")) {
            return;
        }

        setRecalculating(true);
        try {
            const response = await api.post('/deans/recalculate-all-academic-results');
            alert(`✅ Hoàn thành!\n\n- Đã recalculate: ${response.data.recalculated} semester results\n- Đã xóa: ${response.data.deleted} empty results\n- Lỗi: ${response.data.errors}`);
            
            // Refresh kết quả hiện tại nếu đã chọn student
            if (selectedStudent) {
                fetchStudentResults(selectedStudent);
            }
        } catch (err: any) {
            console.error("Error recalculating:", err);
            alert(err.response?.data?.detail || "Lỗi khi recalculate kết quả học tập");
        } finally {
            setRecalculating(false);
        }
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
                <div className="flex gap-3">
                    <button
                        onClick={handleRecalculateAll}
                        disabled={recalculating}
                        className="px-4 py-2 bg-orange-600 text-white rounded-xl hover:bg-orange-700 disabled:opacity-50 flex items-center gap-2 font-medium shadow-sm transition-all"
                        title="Recalculate tất cả kết quả học tập (xóa semester không còn lớp)"
                    >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        {recalculating ? 'Đang xử lý...' : 'Recalculate Tất Cả'}
                    </button>
                    {selectedStudent && (
                        <button
                            onClick={() => fetchStudentResults(selectedStudent)}
                            disabled={loading}
                            className="px-4 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2 font-medium shadow-sm transition-all"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                            </svg>
                            Làm mới
                        </button>
                    )}
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
                                        {studentResults.semester_results
                                            .filter(sem => sem.total_credits > 0) // Chỉ hiển thị semester có enrollments
                                            .map(sem => (
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
