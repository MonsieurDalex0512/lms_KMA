import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Link } from 'react-router-dom';
import { Plus, Trash2, Search, Users, Edit2, Eye } from 'lucide-react';

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
    room?: string;
}

const DeanClasses: React.FC = () => {
    const [classes, setClasses] = useState<ClassItem[]>([]);
    const [courses, setCourses] = useState<any[]>([]);
    const [lecturers, setLecturers] = useState<any[]>([]);
    const [semesters, setSemesters] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingClass, setEditingClass] = useState<ClassItem | null>(null);
    const [formData, setFormData] = useState<any>({
        code: '', course_id: 0, lecturer_id: 0, semester: '', max_students: 50,
        start_week: undefined, end_week: undefined, day_of_week: undefined, start_period: undefined, end_period: undefined,
        room: ''
    });
    const [error, setError] = useState('');

    useEffect(() => {
        fetchData();
    }, []);

    useEffect(() => {
        if (!editingClass && formData.course_id && formData.semester) {
            const selectedCourse = courses.find(c => c.id === formData.course_id);
            if (selectedCourse) {
                const semClean = formData.semester.replace('.', '');
                setFormData((prev: any) => ({ ...prev, code: `${selectedCourse.code}${semClean}` }));
            }
        }
    }, [formData.course_id, formData.semester, courses, editingClass]);

    const fetchData = async () => {
        try {
            const [classesRes, coursesRes, lecturersRes, semestersRes] = await Promise.all([
                api.get('/deans/classes'),
                api.get('/deans/courses'),
                api.get('/deans/lecturers'),
                api.get('/deans/semesters')
            ]);
            setClasses(classesRes.data);
            setCourses(coursesRes.data);
            setLecturers(lecturersRes.data);
            setSemesters(semestersRes.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            if (editingClass) {
                await api.put(`/deans/classes/${editingClass.id}`, formData);
            } else {
                await api.post('/deans/classes', formData);
            }
            setShowModal(false);
            resetForm();
            fetchData();
        } catch (err) {
            setError('Không thể lưu lớp học. Kiểm tra lại thông tin.');
        }
    };

    const resetForm = () => {
        setFormData({
            code: '', course_id: 0, lecturer_id: 0, semester: '', max_students: 50,
            start_week: undefined, end_week: undefined, day_of_week: undefined, start_period: undefined, end_period: undefined,
            room: ''
        });
        setEditingClass(null);
        setError('');
    };

    const openEditModal = (item: ClassItem) => {
        setEditingClass(item);
        setFormData({
            code: item.code,
            course_id: item.course_id,
            lecturer_id: item.lecturer_id,
            semester: item.semester,
            max_students: item.max_students,
            start_week: item.start_week,
            end_week: item.end_week,
            day_of_week: item.day_of_week,
            start_period: item.start_period,
            end_period: item.end_period,
            room: item.room
        });
        setShowModal(true);
    };

    const handleDelete = async (id: number) => {
        if (!window.confirm("Bạn có chắc chắn muốn xóa lớp này?")) return;
        try {
            await api.delete(`/deans/classes/${id}`);
            fetchData();
        } catch (err) {
            alert("Không thể xóa lớp học này");
        }
    };

    const getCourseName = (id: number) => courses.find(c => c.id === id)?.name || 'Unknown';
    const getCourseCode = (id: number) => courses.find(c => c.id === id)?.code || 'Unknown';
    const getLecturerName = (id: number) => lecturers.find(l => l.id === id)?.full_name || 'Unknown';

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Quản Lý Lớp Học</h2>
                    <p className="text-gray-500 text-sm">Danh sách các lớp học trong hệ thống</p>
                </div>
                <button
                    onClick={() => { resetForm(); setShowModal(true); }}
                    className="bg-blue-600 text-white px-5 py-2.5 rounded-xl flex items-center gap-2 hover:bg-blue-700 shadow-lg shadow-blue-500/20 transition-all active:scale-95 font-medium"
                >
                    <Plus className="h-5 w-5" /> Thêm Lớp Học
                </button>
            </div>

            {/* Search Placeholder */}
            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex items-center gap-3 max-w-md">
                <Search className="h-5 w-5 text-gray-400" />
                <input
                    type="text"
                    placeholder="Tìm kiếm lớp học..."
                    className="flex-1 outline-none text-gray-700 bg-transparent"
                />
            </div>

            {showModal && (
                <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-white p-8 rounded-2xl w-full max-w-md shadow-2xl animate-in zoom-in-95 duration-200">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-xl font-bold text-gray-900">{editingClass ? 'Cập Nhật Lớp Học' : 'Thêm Lớp Học Mới'}</h3>
                            <button onClick={() => setShowModal(false)} className="text-gray-400 hover:text-gray-600">✕</button>
                        </div>

                        {error && <p className="bg-red-50 text-red-600 p-3 rounded-lg text-sm mb-4 border border-red-100">{error}</p>}

                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Học Phần</label>
                                    <select
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.course_id}
                                        onChange={e => setFormData({ ...formData, course_id: parseInt(e.target.value) })}
                                        required
                                    >
                                        <option value={0}>Chọn học phần...</option>
                                        {courses.map(c => (
                                            <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                                        ))}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Kỳ học</label>
                                    <select
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.semester}
                                        onChange={e => setFormData({ ...formData, semester: e.target.value })}
                                        required
                                    >
                                        <option value="">Chọn kỳ học...</option>
                                        {semesters.map(s => (
                                            <option key={s.id} value={s.code}>{s.name} ({s.code})</option>
                                        ))}
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Mã lớp (Tự động)</label>
                                <input
                                    className="w-full border border-gray-200 p-3 rounded-xl bg-gray-50 text-gray-500 cursor-not-allowed"
                                    value={formData.code}
                                    readOnly
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Giảng viên</label>
                                <select
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                    value={formData.lecturer_id}
                                    onChange={e => setFormData({ ...formData, lecturer_id: parseInt(e.target.value) })}
                                    required
                                >
                                    <option value={0}>Chọn giảng viên...</option>
                                    {lecturers.map(l => (
                                        <option key={l.id} value={l.id}>{l.full_name} ({l.username})</option>
                                    ))}
                                </select>
                            </div>



                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Sĩ số tối đa</label>
                                    <input
                                        type="number"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.max_students}
                                        onChange={e => setFormData({ ...formData, max_students: parseInt(e.target.value) })}
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Phòng học (Mặc định)</label>
                                    <input
                                        type="text"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.room || ''}
                                        onChange={e => setFormData({ ...formData, room: e.target.value })}
                                        placeholder="VD: A101"
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Tuần bắt đầu</label>
                                    <input
                                        type="number"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.start_week || ''}
                                        onChange={e => setFormData({ ...formData, start_week: parseInt(e.target.value) })}
                                        placeholder="VD: 1"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Tuần kết thúc</label>
                                    <input
                                        type="number"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.end_week || ''}
                                        onChange={e => setFormData({ ...formData, end_week: parseInt(e.target.value) })}
                                        placeholder="VD: 15"
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-3 gap-3">
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Thứ</label>
                                    <select
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.day_of_week || ''}
                                        onChange={e => setFormData({ ...formData, day_of_week: parseInt(e.target.value) })}
                                    >
                                        <option value="">Chọn...</option>
                                        <option value={2}>Thứ 2</option>
                                        <option value={3}>Thứ 3</option>
                                        <option value={4}>Thứ 4</option>
                                        <option value={5}>Thứ 5</option>
                                        <option value={6}>Thứ 6</option>
                                        <option value={7}>Thứ 7</option>
                                        <option value={8}>Chủ Nhật</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Tiết bắt đầu</label>
                                    <input
                                        type="number"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.start_period || ''}
                                        onChange={e => setFormData({ ...formData, start_period: parseInt(e.target.value) })}
                                        placeholder="VD: 1"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Tiết kết thúc</label>
                                    <input
                                        type="number"
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
                                        value={formData.end_period || ''}
                                        onChange={e => setFormData({ ...formData, end_period: parseInt(e.target.value) })}
                                        placeholder="VD: 3"
                                    />
                                </div>
                            </div>

                            <div className="flex justify-end gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    className="text-gray-600 px-5 py-2.5 hover:bg-gray-100 rounded-xl font-medium transition-colors"
                                >
                                    Hủy
                                </button>
                                <button
                                    type="submit"
                                    className="bg-blue-600 text-white px-5 py-2.5 rounded-xl hover:bg-blue-700 font-medium shadow-lg shadow-blue-500/30 transition-all"
                                >
                                    {editingClass ? 'Cập Nhật' : 'Tạo Mới'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div >
            )}

            {
                loading ? (
                    <div className="flex justify-center p-12">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                ) : (
                    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                        <table className="w-full text-left text-sm text-gray-600">
                            <thead className="bg-gray-50/50 text-gray-800 font-semibold uppercase text-xs">
                                <tr>
                                    <th className="px-6 py-4">Mã Lớp</th>
                                    <th className="px-6 py-4">Học Phần</th>
                                    <th className="px-6 py-4">Giảng Viên</th>
                                    <th className="px-6 py-4 text-center">Học Kỳ</th>
                                    <th className="px-6 py-4 text-center">Đã Đăng Ký</th>
                                    <th className="px-6 py-4 text-center">Tối Đa</th>
                                    <th className="px-6 py-4 text-right">Thao Tác</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {classes.map(item => (
                                    <tr key={item.id} className="hover:bg-blue-50/50 transition-colors group">
                                        <td className="px-6 py-4 font-bold text-blue-600">
                                            <div className="flex items-center gap-2">
                                                <Users className="h-4 w-4 text-blue-400" />
                                                {item.code}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="font-medium text-gray-900">{getCourseName(item.course_id)}</div>
                                            <div className="text-xs text-gray-500">{getCourseCode(item.course_id)}</div>
                                        </td>
                                        <td className="px-6 py-4 text-gray-700">{getLecturerName(item.lecturer_id)}</td>
                                        <td className="px-6 py-4 text-center text-gray-600">{item.semester}</td>
                                        <td className="px-6 py-4 text-center">
                                            <span className="bg-blue-50 text-blue-700 px-2.5 py-1 rounded-md text-xs font-bold border border-blue-100">
                                                {(item as any).enrolled_count || 0}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-center">
                                            <span className="bg-gray-50 text-gray-700 px-2.5 py-1 rounded-md text-xs font-bold border border-gray-100">
                                                {item.max_students}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Link
                                                    to={`/classes/${item.id}`}
                                                    className="text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors p-2 rounded-lg"
                                                    title="Chi tiết lớp học"
                                                >
                                                    <Eye className="h-4.5 w-4.5" />
                                                </Link>
                                                <button
                                                    onClick={() => openEditModal(item)}
                                                    className="text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors p-2 rounded-lg"
                                                >
                                                    <Edit2 className="h-4.5 w-4.5" />
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(item.id)}
                                                    className="text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors p-2 rounded-lg"
                                                >
                                                    <Trash2 className="h-4.5 w-4.5" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                                {classes.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-10 text-center text-gray-400 italic">Chưa có lớp học nào</td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )
            }
        </div >
    );
};

export default DeanClasses;
