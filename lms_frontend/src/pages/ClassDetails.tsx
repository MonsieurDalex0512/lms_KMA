import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../services/api';
import { ArrowLeft, Plus, Check } from 'lucide-react';

interface ClassItem {
    id: number;
    code: string;
    course_id: number;
    lecturer_id: number;
    semester: string;
    max_students: number;
    start_week?: number;
    end_week?: number;
    day_of_week?: number;
    start_period?: number;
    end_period?: number;
}

interface UserData {
    id: number;
    username: string;
    email: string;
    full_name: string;
    student_code?: string;
}

const ClassDetails: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [classInfo, setClassInfo] = useState<ClassItem | null>(null);
    const [enrolledStudents, setEnrolledStudents] = useState<UserData[]>([]);
    const [availableStudents, setAvailableStudents] = useState<UserData[]>([]);
    const [selectedStudents, setSelectedStudents] = useState<number[]>([]);
    const [loading, setLoading] = useState(true);
    const [showAddModal, setShowAddModal] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        if (id) {
            fetchClassData();
        }
    }, [id]);

    const fetchClassData = async () => {
        try {
            const [classRes, studentsRes] = await Promise.all([
                api.get(`/deans/classes/${id}`),
                api.get(`/deans/classes/${id}/students`)
            ]);
            setClassInfo(classRes.data);
            setEnrolledStudents(studentsRes.data);
        } catch (err) {
            console.error("Error fetching class data:", err);
            alert("Không tải được dữ liệu lớp học");
            navigate('/classes');
        } finally {
            setLoading(false);
        }
    };

    const handleOpenAddModal = async () => {
        try {
            const response = await api.get('/deans/students');
            const allStudents: UserData[] = response.data;
            const enrolledIds = new Set(enrolledStudents.map(s => s.id));
            const available = allStudents.filter(s => !enrolledIds.has(s.id));
            setAvailableStudents(available);
            setSelectedStudents([]);
            setSearchTerm('');
            setShowAddModal(true);
        } catch (err) {
            console.error(err);
            alert("Lỗi tải danh sách sinh viên");
        }
    };

    const toggleStudentSelection = (studentId: number) => {
        setSelectedStudents(prev =>
            prev.includes(studentId)
                ? prev.filter(id => id !== studentId)
                : [...prev, studentId]
        );
    };

    const handleBulkAdd = async () => {
        if (!classInfo || selectedStudents.length === 0) return;
        try {
            await api.post(`/deans/classes/${classInfo.id}/enrollments/bulk`, {
                student_ids: selectedStudents
            });
            setShowAddModal(false);
            fetchClassData();
            alert(`Đã thêm ${selectedStudents.length} sinh viên vào lớp.`);
        } catch (err: any) {
            console.error(err);
            alert(err.response?.data?.detail || "Lỗi khi thêm sinh viên");
        }
    };

    const filteredAvailable = availableStudents.filter(s =>
        s.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.student_code?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.username.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) return <div className="p-8 text-center text-gray-500">Đang tải...</div>;
    if (!classInfo) return <div className="p-8 text-center text-red-500">Lớp học không tồn tại</div>;

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <button onClick={() => navigate('/classes')} className="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors">
                <ArrowLeft className="h-4 w-4" /> Quay lại danh sách lớp
            </button>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                <div className="flex justify-between items-start">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-900 mb-2">Lớp: {classInfo?.code}</h1>
                        <p className="text-gray-500">Học kỳ: {classInfo?.semester} | Sĩ số: {enrolledStudents?.length || 0} / {classInfo?.max_students}</p>
                    </div>
                    <button
                        onClick={handleOpenAddModal}
                        className="bg-blue-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 hover:bg-blue-700 font-medium shadow-lg shadow-blue-500/20"
                    >
                        <Plus className="h-5 w-5" /> Thêm Sinh Viên
                    </button>
                </div>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <h3 className="px-6 py-4 font-bold text-gray-800 border-b border-gray-100 bg-gray-50/50">Danh sách sinh viên</h3>
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm text-gray-600">
                        <thead className="bg-gray-50 text-gray-800 font-semibold uppercase text-xs">
                            <tr>
                                <th className="px-6 py-3">MSSV</th>
                                <th className="px-6 py-3">Họ và Tên</th>
                                <th className="px-6 py-3">Email</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {enrolledStudents.map(student => (
                                <tr key={student.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-3 font-medium text-gray-900">{student.student_code || '---'}</td>
                                    <td className="px-6 py-3">{student.full_name}</td>
                                    <td className="px-6 py-3">{student.email}</td>
                                </tr>
                            ))}
                            {enrolledStudents.length === 0 && (
                                <tr>
                                    <td colSpan={3} className="px-6 py-8 text-center text-gray-400 italic">Chưa có sinh viên nào trong lớp.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Modal Add Students */}
            {showAddModal && (
                <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-2xl w-full max-w-2xl shadow-2xl animate-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
                        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="text-xl font-bold text-gray-900">Thêm Sinh Viên Vào Lớp</h3>
                            <button onClick={() => setShowAddModal(false)} className="text-gray-400 hover:text-gray-600">✕</button>
                        </div>

                        <div className="p-4 border-b border-gray-100">
                            <input
                                className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none"
                                placeholder="Tìm kiếm theo tên, MSSV..."
                                value={searchTerm}
                                onChange={e => setSearchTerm(e.target.value)}
                            />
                        </div>

                        <div className="flex-1 overflow-y-auto p-2">
                            {filteredAvailable.length === 0 ? (
                                <p className="text-center text-gray-500 py-8">Không tìm thấy sinh viên phù hợp.</p>
                            ) : (
                                <div className="space-y-1">
                                    {filteredAvailable.map(s => (
                                        <div
                                            key={s.id}
                                            className={`flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-colors ${selectedStudents.includes(s.id) ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50 border border-transparent'}`}
                                            onClick={() => toggleStudentSelection(s.id)}
                                        >
                                            <div className={`w-5 h-5 rounded-md border flex items-center justify-center ${selectedStudents.includes(s.id) ? 'bg-blue-600 border-blue-600 text-white' : 'border-gray-300'}`}>
                                                {selectedStudents.includes(s.id) && <Check className="h-3 w-3" />}
                                            </div>
                                            <div>
                                                <div className="font-medium text-gray-900">{s.full_name}</div>
                                                <div className="text-xs text-gray-500">{s.student_code} - {s.email}</div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>

                        <div className="p-6 border-t border-gray-100 flex justify-between items-center bg-gray-50/50 rounded-b-2xl">
                            <span className="text-sm text-gray-600">Đã chọn: <b>{selectedStudents.length}</b></span>
                            <div className="flex gap-3">
                                <button onClick={() => setShowAddModal(false)} className="px-4 py-2 text-gray-600 hover:bg-gray-200 rounded-lg font-medium transition-colors">Hủy</button>
                                <button
                                    onClick={handleBulkAdd}
                                    disabled={selectedStudents.length === 0}
                                    className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium shadow-sm transition-all"
                                >
                                    Thêm vào lớp
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ClassDetails;
