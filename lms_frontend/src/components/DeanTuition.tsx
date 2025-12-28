import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Search, DollarSign, CheckCircle, Clock, AlertCircle, Settings, Save, User, CreditCard } from 'lucide-react';

interface Tuition {
    id: number;
    student_id: number;
    semester: string;
    total_amount: number;
    paid_amount: number;
    status: 'PENDING' | 'PARTIAL' | 'COMPLETED';
}

interface Student {
    id: number;
    student_code: string;
    full_name: string;
}

const DeanTuition: React.FC = () => {
    const [students, setStudents] = useState<Student[]>([]);
    const [tuitions, setTuitions] = useState<Tuition[]>([]);
    const [pricePerCredit, setPricePerCredit] = useState<number>(0);

    const [loading, setLoading] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);
    const [searchTerm, setSearchTerm] = useState('');

    const [editingTuition, setEditingTuition] = useState<Tuition | null>(null);
    const [editAmount, setEditAmount] = useState('');
    const [showModal, setShowModal] = useState(false);

    const [newPrice, setNewPrice] = useState('');

    useEffect(() => {
        fetchStudents();
        fetchSettings();
    }, []);

    const fetchStudents = async () => {
        try {
            const res = await api.get('/deans/students');
            setStudents(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    const fetchSettings = async () => {
        try {
            const res = await api.get('/deans/tuition-settings');
            setPricePerCredit(res.data.price_per_credit);
            setNewPrice(res.data.price_per_credit.toString());
        } catch (err) {
            console.error(err);
        }
    };

    const updateGlobalPrice = async () => {
        if (!confirm('Bạn có chắc chắn muốn cập nhật giá tín chỉ? Giá này sẽ áp dụng cho các tính toán TƯƠNG LAI.')) return;
        try {
            const res = await api.post('/deans/tuition-settings', { price_per_credit: parseInt(newPrice) });
            setPricePerCredit(res.data.price_per_credit);
            alert('Cập nhật giá tín chỉ thành công!');
        } catch (err) {
            alert('Lỗi cập nhật giá tín chỉ');
        }
    };

    const fetchStudentTuitions = async (studentId: number) => {
        setLoading(true);
        try {

            const res = await api.get('/deans/tuitions');
            const studentTuitions = res.data.filter((t: Tuition) => t.student_id === studentId);
            setTuitions(studentTuitions);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSelectStudent = (student: Student) => {
        setSelectedStudent(student);
        fetchStudentTuitions(student.id);
    };

    const handleUpdatePayment = async () => {
        if (!editingTuition) return;
        try {
            await api.put(`/deans/tuitions/${editingTuition.id}`, {
                paid_amount: parseInt(editAmount)
            });
            alert('Cập nhật thành công!');
            setShowModal(false);
            if (selectedStudent) fetchStudentTuitions(selectedStudent.id);
        } catch (error) {
            alert('Cập nhật thất bại');
        }
    };

    const openEditModal = (tuition: Tuition) => {
        setEditingTuition(tuition);
        setEditAmount(tuition.paid_amount.toString());
        setShowModal(true);
    };

    const formatCurrency = (amount: number) => {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
    };

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'COMPLETED':
                return <span className="px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 flex items-center gap-1"><CheckCircle size={14} /> Hoàn thành</span>;
            case 'PARTIAL':
                return <span className="px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-800 flex items-center gap-1"><Clock size={14} /> Một phần</span>;
            default:
                return <span className="px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800 flex items-center gap-1"><AlertCircle size={14} /> Chưa đóng</span>;
        }
    };

    const filteredStudents = students.filter(s =>
        s.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.student_code.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6 h-[calc(100vh-100px)] flex flex-col">
            <div className="flex justify-between items-center">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Quản lý Học phí</h2>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 flex-1 overflow-hidden">
                {/* LEFT: Student List */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col overflow-hidden">
                    <div className="p-4 border-b border-gray-100">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                placeholder="Tìm sinh viên..."
                                className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                    </div>
                    <div className="flex-1 overflow-y-auto">
                        {filteredStudents.map(student => (
                            <div
                                key={student.id}
                                onClick={() => handleSelectStudent(student)}
                                className={`p-4 border-b border-gray-50 cursor-pointer hover:bg-gray-50 transition-colors ${selectedStudent?.id === student.id ? 'bg-blue-50 border-l-4 border-l-blue-600' : ''}`}
                            >
                                <div className="font-medium text-gray-900">{student.full_name}</div>
                                <div className="text-sm text-gray-500">{student.student_code}</div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* RIGHT: Details & Settings */}
                <div className="lg:col-span-2 flex flex-col gap-6 overflow-hidden">
                    {/* Settings Card */}
                    <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-blue-100 rounded-lg text-blue-600">
                                <Settings size={20} />
                            </div>
                            <div>
                                <h3 className="font-medium text-gray-900">Đơn giá tín chỉ</h3>
                                <p className="text-sm text-gray-500">Hiện tại: {formatCurrency(pricePerCredit)} / tín chỉ</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-2">
                            <input
                                type="number"
                                value={newPrice}
                                onChange={(e) => setNewPrice(e.target.value)}
                                className="w-32 px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                                placeholder="Nhập giá mới"
                            />
                            <button
                                onClick={updateGlobalPrice}
                                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
                            >
                                <Save size={16} /> Lưu
                            </button>
                        </div>
                    </div>

                    {/* Student Tuition Details */}
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 flex-1 flex flex-col overflow-hidden">
                        {selectedStudent ? (
                            <>
                                <div className="p-6 border-b border-gray-100 bg-gray-50">
                                    <div className="flex items-center gap-4">
                                        <div className="h-12 w-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center">
                                            <User size={24} />
                                        </div>
                                        <div>
                                            <h3 className="text-xl font-bold text-gray-900">{selectedStudent.full_name}</h3>
                                            <p className="text-gray-600">{selectedStudent.student_code}</p>
                                        </div>
                                    </div>
                                </div>
                                <div className="flex-1 overflow-y-auto p-6">
                                    <h4 className="font-bold text-gray-800 mb-4 flex items-center gap-2">
                                        <CreditCard size={18} /> Danh sách học phí theo kỳ
                                    </h4>

                                    {loading ? (
                                        <p className="text-gray-500">Đang tải...</p>
                                    ) : tuitions.length === 0 ? (
                                        <div className="p-8 text-center text-gray-500 border-2 border-dashed rounded-xl">
                                            Chưa có dữ liệu học phí cho sinh viên này.
                                        </div>
                                    ) : (
                                        <div className="space-y-4">
                                            {tuitions.map(item => (
                                                <div key={item.id} className="border border-gray-200 rounded-xl p-4 hover:shadow-md transition-shadow">
                                                    <div className="flex justify-between items-start mb-4">
                                                        <div>
                                                            <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-lg text-sm font-semibold">
                                                                {item.semester}
                                                            </span>
                                                        </div>
                                                        {getStatusBadge(item.status)}
                                                    </div>

                                                    <div className="grid grid-cols-3 gap-4 mb-4">
                                                        <div>
                                                            <p className="text-xs text-gray-500 uppercase">Tổng học phí</p>
                                                            <p className="font-bold text-lg">{formatCurrency(item.total_amount)}</p>
                                                        </div>
                                                        <div>
                                                            <p className="text-xs text-gray-500 uppercase">Đã đóng</p>
                                                            <p className="font-bold text-lg text-green-600">{formatCurrency(item.paid_amount)}</p>
                                                        </div>
                                                        <div>
                                                            <p className="text-xs text-gray-500 uppercase">Còn nợ</p>
                                                            <p className="font-bold text-lg text-red-600">{formatCurrency(item.total_amount - item.paid_amount)}</p>
                                                        </div>
                                                    </div>

                                                    <div className="flex justify-end pt-3 border-t border-gray-100">
                                                        <button
                                                            onClick={() => openEditModal(item)}
                                                            className="text-blue-600 font-medium hover:underline text-sm flex items-center gap-1"
                                                        >
                                                            <DollarSign size={14} /> Cập nhật đóng tiền
                                                        </button>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            </>
                        ) : (
                            <div className="h-full flex flex-col items-center justify-center text-gray-500 p-8">
                                <div className="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                                    <User size={32} className="text-gray-400" />
                                </div>
                                <p>Chọn một sinh viên để xem chi tiết học phí</p>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Edit Payment Modal */}
            {showModal && editingTuition && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6 animate-in zoom-in-95 duration-200">
                        <h3 className="text-xl font-bold mb-4">Cập nhật học phí ({editingTuition.semester})</h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Tổng học phí</label>
                                <div className="p-3 bg-gray-100 rounded-lg font-medium text-gray-800">
                                    {formatCurrency(editingTuition.total_amount)}
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Số tiền đã đóng</label>
                                <input
                                    type="number"
                                    className="w-full p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    value={editAmount}
                                    onChange={(e) => setEditAmount(e.target.value)}
                                    placeholder="Nhập số tiền..."
                                />
                            </div>
                            <div className="flex items-center gap-2 text-sm text-gray-500">
                                <AlertCircle size={14} />
                                <span>Trạng thái sẽ được cập nhật tự động theo số tiền đóng.</span>
                            </div>
                        </div>
                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => setShowModal(false)}
                                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium text-gray-700"
                            >
                                Hủy
                            </button>
                            <button
                                onClick={handleUpdatePayment}
                                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
                            >
                                Lưu thay đổi
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default DeanTuition;
