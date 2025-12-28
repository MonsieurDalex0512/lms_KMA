import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Edit2, Save, X } from 'lucide-react';

interface ClassItem {
    id: number;
    code: string;
    course?: {
        name: string;
    }
}

interface GradeItem {
    id: number;
    grade_type: string;
    score: number;
    weight: number;
}

interface StudentGrade {
    enrollment_id: number;
    student_id: number;
    student_code: string;
    full_name: string;
    grades: GradeItem[];
}

const DeanGrades: React.FC = () => {
    const [classes, setClasses] = useState<ClassItem[]>([]);
    const [selectedClass, setSelectedClass] = useState<number | null>(null);
    const [students, setStudents] = useState<StudentGrade[]>([]);
    const [loading, setLoading] = useState(false);

    const [editingGrade, setEditingGrade] = useState<{ enrollmentId: number, type: 'midterm' | 'final', gradeId?: number, score: number } | null>(null);

    useEffect(() => {
        api.get('/deans/classes').then(res => setClasses(res.data));
    }, []);

    const fetchGrades = () => {
        if (selectedClass) {
            setLoading(true);
            api.get(`/deans/classes/${selectedClass}/grades`)
                .then(res => setStudents(res.data))
                .catch(err => {
                    console.error(err);
                    setStudents([]);
                })
                .finally(() => setLoading(false));
        }
    };

    useEffect(() => {
        if (selectedClass) {
            fetchGrades();
        } else {
            setStudents([]);
        }
    }, [selectedClass]);

    const handleSaveGrade = async () => {
        if (!editingGrade) return;

        try {
            if (editingGrade.gradeId) {
                await api.put(`/deans/grades/${editingGrade.gradeId}`, {
                    grade_type: editingGrade.type,
                    score: editingGrade.score,
                    weight: editingGrade.type === 'midterm' ? 0.3 : 0.7
                });
            } else {
                await api.post('/deans/grades', {
                    enrollment_id: editingGrade.enrollmentId,
                    grade_type: editingGrade.type,
                    score: editingGrade.score,
                    weight: editingGrade.type === 'midterm' ? 0.3 : 0.7
                });
            }
            fetchGrades();
            setEditingGrade(null);
        } catch (err: any) {
            alert(err.response?.data?.detail || "Không thể lưu điểm");
        }
    };

    const startEdit = (student: StudentGrade, type: 'midterm' | 'final') => {
        const grade = student.grades.find(g => g.grade_type === type);
        setEditingGrade({
            enrollmentId: student.enrollment_id,
            type: type,
            gradeId: grade?.id,
            score: grade ? grade.score : 0
        });
    };

    const renderGradeCell = (student: StudentGrade, type: 'midterm' | 'final') => {
        const grade = student.grades.find(g => g.grade_type === type);
        const isEditing = editingGrade?.enrollmentId === student.enrollment_id && editingGrade?.type === type;

        if (isEditing) {
            return (
                <div className="flex items-center gap-2 justify-center">
                    <input
                        type="number" step="0.1" min="0" max="10"
                        className="w-16 border border-purple-300 p-1 rounded-md focus:ring-2 focus:ring-purple-500/20 outline-none text-center"
                        value={editingGrade.score}
                        onChange={e => setEditingGrade({ ...editingGrade, score: parseFloat(e.target.value) })}
                        autoFocus
                        onKeyDown={e => {
                            if (e.key === 'Enter') handleSaveGrade();
                            if (e.key === 'Escape') setEditingGrade(null);
                        }}
                    />
                    <button onClick={handleSaveGrade} className="text-green-600 hover:bg-green-50 p-1 rounded"><Save size={16} /></button>
                    <button onClick={() => setEditingGrade(null)} className="text-red-500 hover:bg-red-50 p-1 rounded"><X size={16} /></button>
                </div>
            );
        }

        if (grade) {
            return (
                <div className="flex items-center justify-center gap-2 group">
                    <span className={`px-2.5 py-1 rounded-md font-bold text-sm ${grade.score >= 5 ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
                        {grade.score}
                    </span>
                    <button
                        onClick={() => startEdit(student, type)}
                        className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-purple-600 transition-opacity"
                    >
                        <Edit2 size={14} />
                    </button>
                </div>
            );
        }

        return (
            <div className="text-center">
                <button
                    onClick={() => startEdit(student, type)}
                    className="text-xs text-gray-400 hover:text-purple-600 hover:bg-purple-50 px-2 py-1 rounded border border-dashed border-gray-300 hover:border-purple-300 transition-all"
                >
                    + Nhập điểm
                </button>
            </div>
        );
    };

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div>
                <h2 className="text-2xl font-bold text-gray-900">Quản Lý Điểm Số</h2>
                <p className="text-gray-500 text-sm">Xem và quản lý bảng điểm theo lớp học</p>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                <div className="max-w-md">
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Chọn Lớp Học</label>
                    <select
                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 outline-none transition-all cursor-pointer"
                        onChange={e => setSelectedClass(parseInt(e.target.value))}
                        value={selectedClass || ''}
                    >
                        <option value="">-- Chọn lớp để xem điểm --</option>
                        {classes.map(c => (
                            <option key={c.id} value={c.id}>{c.code} - {c.course?.name || 'Học phần'}</option>
                        ))}
                    </select>
                </div>
            </div>

            {selectedClass && (
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 border-b border-gray-50 bg-gray-50/50 flex justify-between items-center">
                        <h3 className="font-bold text-gray-800">Danh Sách Bảng Điểm</h3>
                        <div className="text-sm text-gray-500">
                            Sĩ số: <span className="font-medium text-gray-900">{students.length}</span>
                        </div>
                    </div>
                    {loading ? (
                        <div className="flex justify-center p-12">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
                        </div>
                    ) : (
                        <table className="w-full text-left text-sm text-gray-600">
                            <thead className="bg-gray-50/50 text-gray-800 font-semibold uppercase text-xs">
                                <tr>
                                    <th className="px-6 py-4 w-1/12">#</th>
                                    <th className="px-6 py-4 w-2/12">MSSV</th>
                                    <th className="px-6 py-4 w-3/12">Họ và Tên</th>
                                    <th className="px-6 py-4 text-center w-2/12">Giữa Kỳ (30%)</th>
                                    <th className="px-6 py-4 text-center w-2/12">Cuối Kỳ (70%)</th>
                                    <th className="px-6 py-4 text-center w-2/12">Tổng Kết</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {students.map((student, index) => {
                                    const midterm = student.grades.find(g => g.grade_type === 'midterm');
                                    const final = student.grades.find(g => g.grade_type === 'final');
                                    let total = null;
                                    if (midterm && final) {
                                        total = (midterm.score * 0.3 + final.score * 0.7).toFixed(1);
                                    }

                                    return (
                                        <tr key={student.student_id} className="hover:bg-purple-50/30 transition-colors">
                                            <td className="px-6 py-4 text-gray-400">{index + 1}</td>
                                            <td className="px-6 py-4 font-medium text-gray-900">{student.student_code}</td>
                                            <td className="px-6 py-4">{student.full_name}</td>
                                            <td className="px-6 py-4">
                                                {renderGradeCell(student, 'midterm')}
                                            </td>
                                            <td className="px-6 py-4">
                                                {renderGradeCell(student, 'final')}
                                            </td>
                                            <td className="px-6 py-4 text-center">
                                                {total !== null ? (
                                                    <span className={`px-2.5 py-1 rounded-md font-bold text-xs ${parseFloat(total) >= 4 ? 'bg-blue-50 text-blue-700' : 'bg-red-50 text-red-700'}`}>
                                                        {total}
                                                    </span>
                                                ) : <span className="text-gray-300">-</span>}
                                            </td>
                                        </tr>
                                    );
                                })}
                                {students.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-12 text-center text-gray-400 italic">
                                            Lớp này chưa có sinh viên nào.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    )}
                </div>
            )}
        </div>
    );
};

export default DeanGrades;
