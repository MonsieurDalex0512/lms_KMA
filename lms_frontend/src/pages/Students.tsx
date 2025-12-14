import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Plus, User, Mail, Phone, Trash2, Edit2 } from 'lucide-react';

interface UserData {
    id: number;
    username: string;
    email: string;
    full_name: string;
    phone_number: string;
    is_active: boolean;
    student_code?: string;
    department_name?: string;
}

interface Department {
    id: number;
    name: string;
}

const Students: React.FC = () => {
    const [students, setStudents] = useState<UserData[]>([]);
    const [departments, setDepartments] = useState<Department[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingUser, setEditingUser] = useState<UserData | null>(null);
    const [formData, setFormData] = useState({
        username: '', email: '', password: '12345678', full_name: '', phone_number: '', student_code: '', department_id: ''
    });
    const [error, setError] = useState('');
    const [page, setPage] = useState(0);
    const [pageSize] = useState(20);
    const [hasMore, setHasMore] = useState(true);

    useEffect(() => {
        fetchStudents();
        fetchDepartments();
    }, [page]);

    const fetchDepartments = async () => {
        try {
            const response = await api.get('/deans/departments');
            setDepartments(response.data);
        } catch (err) {
            console.error('Failed to fetch departments:', err);
        }
    };

    const fetchStudents = async () => {
        setLoading(true);
        try {
            const response = await api.get(`/deans/students?skip=${page * pageSize}&limit=${pageSize}`);
            setStudents(response.data);
            setHasMore(response.data.length === pageSize);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            if (editingUser) {
                await api.put(`/deans/students/${editingUser.id}`, formData);
            } else {
                await api.post('/deans/students', { ...formData, role: 'student' });
            }
            setShowModal(false);
            resetForm();
            fetchStudents();
        } catch (err) {
            setError('Không thể lưu thông tin sinh viên');
        }
    };

    const removeVietnameseTones = (str: string) => {
        return str
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd').replace(/Đ/g, 'D');
    }

    useEffect(() => {
        if (!editingUser && formData.full_name) {
            const namePart = removeVietnameseTones(formData.full_name).toLowerCase().replace(/\s/g, '');
            const codePart = formData.student_code ? formData.student_code.slice(-4) : '';
            const newUsername = `${namePart}${codePart}`;
            setFormData(prev => ({
                ...prev,
                username: newUsername,
                email: `${newUsername}@student.university.edu.vn`
            }));
        }
    }, [formData.full_name, formData.student_code, editingUser]);

    const resetForm = () => {
        setFormData({ username: '', email: '', password: '12345678', full_name: '', phone_number: '', student_code: '', department_id: '' });
        setEditingUser(null);
        setError('');
    };

    const openEditModal = (user: UserData) => {
        setEditingUser(user);
        setFormData({
            username: user.username,
            email: user.email,
            password: '',
            full_name: user.full_name,
            phone_number: user.phone_number || '',
            student_code: user.student_code || '',
            department_id: ''
        });
        setShowModal(true);
    };

    const handleDelete = async (id: number) => {
        if (!window.confirm("Bạn có chắc chắn muốn xóa?")) return;
        try {
            await api.delete(`/deans/students/${id}`);
            fetchStudents();
        } catch (err) {
            alert("Không thể xóa sinh viên này");
        }
    }

    return (
        <div className="space-y-6 animate-in fade-in duration-500 pb-10">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Quản Lý Sinh Viên</h2>
                    <p className="text-gray-500 text-sm">Danh sách sinh viên toàn trường</p>
                </div>
                <button
                    onClick={() => { resetForm(); setShowModal(true); }}
                    className="bg-green-600 text-white px-5 py-2.5 rounded-xl flex items-center gap-2 hover:bg-green-700 shadow-lg shadow-green-500/20 transition-all active:scale-95 font-medium"
                >
                    <Plus className="h-5 w-5" /> Thêm Sinh Viên
                </button>
            </div>

            {showModal && (
                <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-white p-8 rounded-2xl w-full max-w-md shadow-2xl animate-in zoom-in-95 duration-200 max-h-[90vh] overflow-y-auto">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-xl font-bold text-gray-900">{editingUser ? 'Cập Nhật Sinh Viên' : 'Thêm Sinh Viên Mới'}</h3>
                            <button onClick={() => setShowModal(false)} className="text-gray-400 hover:text-gray-600">✕</button>
                        </div>

                        {error && <p className="bg-red-50 text-red-600 p-3 rounded-lg text-sm mb-4 border border-red-100">{error}</p>}

                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Họ và tên</label>
                                <input
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                    value={formData.full_name}
                                    onChange={e => setFormData({ ...formData, full_name: e.target.value })}
                                    required
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Mã sinh viên (MSSV)</label>
                                    <input
                                        className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                        value={formData.student_code}
                                        onChange={e => setFormData({ ...formData, student_code: e.target.value })}
                                        placeholder="VD: 20240001"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1">Tên đăng nhập</label>
                                    <input
                                        className={`w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all ${editingUser ? 'bg-gray-50 text-gray-500' : ''}`}
                                        value={formData.username}
                                        readOnly={!!editingUser}
                                        onChange={e => setFormData({ ...formData, username: e.target.value })}
                                        required
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Email</label>
                                <input
                                    type="email"
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                    value={formData.email}
                                    onChange={e => setFormData({ ...formData, email: e.target.value })}
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Mật khẩu</label>
                                <input
                                    type="password"
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                    value={formData.password}
                                    onChange={e => setFormData({ ...formData, password: e.target.value })}
                                    placeholder={editingUser ? "Để trống nếu không đổi" : "Mặc định: 12345678"}
                                    required={!editingUser}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Số điện thoại</label>
                                <input
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                    value={formData.phone_number}
                                    onChange={e => setFormData({ ...formData, phone_number: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-semibold text-gray-700 mb-1">Khoa/Viện</label>
                                <select
                                    className="w-full border border-gray-200 p-3 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 outline-none transition-all"
                                    value={formData.department_id}
                                    onChange={e => setFormData({ ...formData, department_id: e.target.value })}
                                >
                                    <option value="">-- Chọn khoa/viện --</option>
                                    {departments.map(dept => (
                                        <option key={dept.id} value={dept.id}>{dept.name}</option>
                                    ))}
                                </select>
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
                                    className="bg-green-600 text-white px-5 py-2.5 rounded-xl hover:bg-green-700 font-medium shadow-lg shadow-green-500/30 transition-all"
                                >
                                    {editingUser ? 'Cập Nhật' : 'Tạo Mới'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {loading ? (
                <div className="flex justify-center p-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
                </div>
            ) : (
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <table className="w-full text-left text-sm text-gray-600">
                        <thead className="bg-gray-50/50 text-gray-800 font-semibold uppercase text-xs">
                            <tr>
                                <th className="px-6 py-4">MSSV</th>
                                <th className="px-6 py-4">Sinh Viên</th>
                                <th className="px-6 py-4">Khoa/Viện</th>
                                <th className="px-6 py-4">Liên Hệ</th>
                                <th className="px-6 py-4">Trạng Thái</th>
                                <th className="px-6 py-4 text-right">Thao Tác</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {students.map(student => (
                                <tr key={student.id} className="hover:bg-green-50/30 transition-colors group">
                                    <td className="px-6 py-4 font-medium text-gray-900">
                                        {student.student_code || '---'}
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-4">
                                            <div className="bg-green-100 p-3 rounded-xl shadow-sm">
                                                <User className="h-5 w-5 text-green-600" />
                                            </div>
                                            <div>
                                                <div className="font-bold text-gray-900 text-base">{student.full_name || 'Chưa cập nhật tên'}</div>
                                                <div className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full w-fit mt-1">@{student.username}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className="text-sm text-gray-600">{student.department_name || '-'}</span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="space-y-1.5">
                                            <div className="flex items-center gap-2 text-gray-600">
                                                <Mail className="h-3.5 w-3.5 text-gray-400" /> {student.email}
                                            </div>
                                            {student.phone_number && (
                                                <div className="flex items-center gap-2 text-gray-600">
                                                    <Phone className="h-3.5 w-3.5 text-gray-400" /> {student.phone_number}
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${student.is_active ? 'bg-green-100 text-green-700 border border-green-200' : 'bg-red-100 text-red-700 border border-red-200'}`}>
                                            {student.is_active ? 'Hoạt động' : 'Đã khóa'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-2">
                                            <button
                                                onClick={() => openEditModal(student)}
                                                className="text-gray-400 hover:text-green-600 hover:bg-green-50 transition-colors p-2 rounded-lg"
                                            >
                                                <Edit2 className="h-4.5 w-4.5" />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(student.id)}
                                                className="text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors p-2 rounded-lg"
                                            >
                                                <Trash2 className="h-4.5 w-4.5" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {students.length === 0 && (
                                <tr>
                                    <td colSpan={6} className="px-6 py-10 text-center text-gray-400 italic">Chưa có sinh viên nào</td>
                                </tr>
                            )}
                        </tbody>
                    </table>

                    <div className="p-4 border-t border-gray-100 flex justify-end gap-2">
                        <button
                            disabled={page === 0}
                            onClick={() => setPage(p => Math.max(0, p - 1))}
                            className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg disabled:opacity-50"
                        >
                            Trước
                        </button>
                        <button
                            disabled={!hasMore}
                            onClick={() => setPage(p => p + 1)}
                            className="px-4 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded-lg disabled:opacity-50"
                        >
                            Tiếp
                        </button>
                    </div>
                </div >
            )}
        </div >
    );
};

export default Students;
