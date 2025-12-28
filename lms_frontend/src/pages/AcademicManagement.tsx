import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Plus, Trash2, Edit2, CheckCircle, Calendar, Power } from 'lucide-react';

interface AcademicYear {
    id: number;
    year: string;
    start_date: string;
    end_date: string;
    is_active: boolean;
}

interface Semester {
    id: number;
    code: string;
    name: string;
    academic_year_id: number;
    start_date: string;
    end_date: string;
    is_active: boolean;
    semester_number: number;
}

const AcademicManagement: React.FC = () => {
    const [years, setYears] = useState<AcademicYear[]>([]);
    const [semesters, setSemesters] = useState<Semester[]>([]);
    const [selectedYear, setSelectedYear] = useState<number | null>(null);

    const [showYearForm, setShowYearForm] = useState(false);
    const [showSemesterForm, setShowSemesterForm] = useState(false);
    const [editingYear, setEditingYear] = useState<AcademicYear | null>(null);
    const [editingSemester, setEditingSemester] = useState<Semester | null>(null);

    const [yearFormData, setYearFormData] = useState({ year: '', start_date: '', end_date: '', is_active: true });
    const [semesterFormData, setSemesterFormData] = useState({
        code: '', name: '', semester_number: 1, start_date: '', end_date: ''
    });

    useEffect(() => {
        fetchYears();
        fetchSemesters();
    }, []);

    const fetchYears = async () => {
        try {
            const res = await api.get('/deans/academic-years');
            setYears(res.data);
        } catch (error) { console.error(error); }
    };

    const fetchSemesters = async () => {
        try {
            const res = await api.get('/deans/semesters');
            setSemesters(res.data);
        } catch (error) { console.error(error); }
    };

    const handleSaveYear = async () => {
        try {
            if (editingYear) {
                await api.put(`/deans/academic-years/${editingYear.id}`, yearFormData);
            } else {
                await api.post('/deans/academic-years', yearFormData);
            }
            setShowYearForm(false);
            setEditingYear(null);
            setYearFormData({ year: '', start_date: '', end_date: '', is_active: true });
            fetchYears();
        } catch (error) { alert('Lỗi lưu năm học'); }
    };

    const handleDeleteYear = async (id: number) => {
        if (!window.confirm("Xóa năm học này?")) return;
        try {
            await api.delete(`/deans/academic-years/${id}`);
            fetchYears();
            if (selectedYear === id) setSelectedYear(null);
        } catch (e) { alert("Lỗi xóa năm học"); }
    };

    const handleEditYear = (year: AcademicYear) => {
        setEditingYear(year);
        setYearFormData({
            year: year.year,
            start_date: year.start_date,
            end_date: year.end_date,
            is_active: year.is_active
        });
        setShowYearForm(true);
    };



    const handleSaveSemester = async () => {
        if (!selectedYear) return;
        try {
            if (editingSemester) {
                await api.put(`/deans/semesters/${editingSemester.id}`, semesterFormData);
            } else {
                await api.post('/deans/semesters', {
                    ...semesterFormData,
                    academic_year_id: selectedYear,
                    is_active: false
                });
            }
            setShowSemesterForm(false);
            setEditingSemester(null);
            setSemesterFormData({ code: '', name: '', semester_number: 1, start_date: '', end_date: '' });
            fetchSemesters();
        } catch (error) { alert('Lỗi lưu học kỳ'); }
    };

    const handleDeleteSemester = async (id: number) => {
        if (!window.confirm("Xóa học kỳ này?")) return;
        try {
            await api.delete(`/deans/semesters/${id}`);
            fetchSemesters();
        } catch (e) { alert("Lỗi xóa học kỳ"); }
    };

    const handleEditSemester = (sem: Semester) => {
        setEditingSemester(sem);
        setSemesterFormData({
            code: sem.code,
            name: sem.name,
            semester_number: sem.semester_number,
            start_date: sem.start_date,
            end_date: sem.end_date
        });
        setShowSemesterForm(true);
    };

    const handleActivateSemester = async (id: number) => {
        if (!window.confirm("Kích hoạt học kỳ này? Các học kỳ khác sẽ bị vô hiệu.")) return;
        try {
            await api.post(`/deans/semesters/${id}/activate`);
            fetchSemesters();
        } catch (e) { alert("Lỗi kích hoạt"); }
    };

    const filteredSemesters = semesters.filter(s => s.academic_year_id === selectedYear);

    return (
        <div className="space-y-6">
            <h1 className="text-2xl font-bold text-gray-800">Quản Lý Năm Học & Học Kỳ</h1>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Academic Years List */}
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 col-span-1">
                    <div className="flex justify-between items-center mb-4">
                        <h2 className="text-lg font-semibold flex items-center gap-2">
                            <Calendar className="h-5 w-5 text-blue-600" /> Năm Học
                        </h2>
                        <button onClick={() => { setShowYearForm(true); setEditingYear(null); setYearFormData({ year: '', start_date: '', end_date: '', is_active: true }); }} className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100">
                            <Plus className="h-4 w-4" />
                        </button>
                    </div>

                    {showYearForm && (
                        <div className="mb-4 p-4 bg-gray-50 rounded-lg space-y-3 border border-blue-100">
                            <h3 className="font-semibold text-sm text-blue-800">{editingYear ? 'Sửa Năm Học' : 'Thêm Năm Học'}</h3>
                            <input
                                placeholder="Ví dụ: 2023-2024"
                                className="w-full p-2 border rounded"
                                value={yearFormData.year}
                                onChange={e => setYearFormData({ ...yearFormData, year: e.target.value })}
                            />
                            <div className="grid grid-cols-2 gap-2">
                                <input type="date" className="p-2 border rounded" value={yearFormData.start_date} onChange={e => setYearFormData({ ...yearFormData, start_date: e.target.value })} />
                                <input type="date" className="p-2 border rounded" value={yearFormData.end_date} onChange={e => setYearFormData({ ...yearFormData, end_date: e.target.value })} />
                            </div>
                            <div className="flex items-center gap-2" onClick={e => e.stopPropagation()}>
                                <span className="text-sm text-gray-600">Active:</span>
                                <button
                                    onClick={() => setYearFormData({ ...yearFormData, is_active: !yearFormData.is_active })}
                                    className={`w-10 h-5 rounded-full flex items-center px-1 transition-colors ${yearFormData.is_active ? 'bg-green-500' : 'bg-gray-300'}`}
                                >
                                    <div className={`w-3 h-3 bg-white rounded-full transition-transform ${yearFormData.is_active ? 'translate-x-5' : ''}`} />
                                </button>
                            </div>
                            <div className="flex gap-2 justify-end">
                                <button onClick={() => setShowYearForm(false)} className="px-3 py-1 bg-gray-200 rounded text-sm text-gray-700">Hủy</button>
                                <button onClick={handleSaveYear} className="px-3 py-1 bg-blue-600 text-white rounded text-sm">Lưu</button>
                            </div>
                        </div>
                    )}

                    <div className="space-y-2">
                        {years.map(year => (
                            <div
                                key={year.id}
                                className={`rounded-lg border transition-colors flex justify-between items-center overflow-hidden
                                    ${selectedYear === year.id ? 'bg-blue-50 border-blue-200 ring-1 ring-blue-300' : 'bg-white border-gray-100 hover:border-gray-200'}`}
                            >
                                <div
                                    className="p-3 flex-1 cursor-pointer"
                                    onClick={() => setSelectedYear(year.id)}
                                >
                                    <div className="flex items-center gap-2">
                                        <p className="font-medium text-gray-900">{year.year}</p>
                                        <span className={`w-2 h-2 rounded-full ${year.is_active ? 'bg-green-500' : 'bg-gray-300'}`} />
                                    </div>
                                    <p className="text-xs text-gray-500">{year.start_date} - {year.end_date}</p>
                                </div>
                                <div className="flex flex-col border-l border-gray-100 bg-gray-50 h-full">
                                    <button onClick={(e) => { e.stopPropagation(); handleEditYear(year) }} className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-100 h-full flex items-center justify-center">
                                        <Edit2 className="h-4 w-4" />
                                    </button>
                                    <button onClick={(e) => { e.stopPropagation(); handleDeleteYear(year.id) }} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 h-full flex items-center justify-center border-t border-gray-100">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Semesters List */}
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 col-span-2">
                    <div className="flex justify-between items-center mb-4">
                        <h2 className="text-lg font-semibold">
                            {selectedYear
                                ? `Học Kỳ của Năm ${years.find(y => y.id === selectedYear)?.year}`
                                : 'Chọn năm học để xem học kỳ'}
                        </h2>
                        {selectedYear && (
                            <button onClick={() => { setShowSemesterForm(true); setEditingSemester(null); setSemesterFormData({ code: '', name: '', semester_number: 1, start_date: '', end_date: '' }); }} className="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2 text-sm font-medium">
                                <Plus className="h-4 w-4" /> Thêm Học Kỳ
                            </button>
                        )}
                    </div>

                    {showSemesterForm && selectedYear && (
                        <div className="mb-6 p-4 bg-gray-50 rounded-lg border border-gray-200 grid grid-cols-2 gap-4">
                            <div className="col-span-2 text-sm font-semibold text-blue-800">{editingSemester ? 'Cập Nhật Học Kỳ' : 'Thêm Học Kỳ Mới'}</div>
                            <div className="col-span-2 md:col-span-1">
                                <label className="block text-xs font-medium text-gray-500 mb-1">Mã Học Kỳ</label>
                                <input
                                    placeholder="20231"
                                    className="w-full p-2 border rounded"
                                    value={semesterFormData.code}
                                    onChange={e => setSemesterFormData({ ...semesterFormData, code: e.target.value })}
                                />
                            </div>
                            <div className="col-span-2 md:col-span-1">
                                <label className="block text-xs font-medium text-gray-500 mb-1">Tên Học Kỳ</label>
                                <input
                                    placeholder="Học kỳ 1"
                                    className="w-full p-2 border rounded"
                                    value={semesterFormData.name}
                                    onChange={e => setSemesterFormData({ ...semesterFormData, name: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-gray-500 mb-1">Số thứ tự</label>
                                <select
                                    className="w-full p-2 border rounded"
                                    value={semesterFormData.semester_number}
                                    onChange={e => setSemesterFormData({ ...semesterFormData, semester_number: parseInt(e.target.value) })}
                                >
                                    <option value={1}>1</option>
                                    <option value={2}>2</option>
                                    <option value={3}>3</option>
                                </select>
                            </div>
                            <div className="grid grid-cols-2 gap-2 col-span-2 md:col-span-1">
                                <div>
                                    <label className="block text-xs font-medium text-gray-500 mb-1">Bắt đầu</label>
                                    <input type="date" className="w-full p-2 border rounded" value={semesterFormData.start_date} onChange={e => setSemesterFormData({ ...semesterFormData, start_date: e.target.value })} />
                                </div>
                                <div>
                                    <label className="block text-xs font-medium text-gray-500 mb-1">Kết thúc</label>
                                    <input type="date" className="w-full p-2 border rounded" value={semesterFormData.end_date} onChange={e => setSemesterFormData({ ...semesterFormData, end_date: e.target.value })} />
                                </div>
                            </div>
                            <div className="col-span-2 flex justify-end gap-2 mt-2">
                                <button onClick={() => setShowSemesterForm(false)} className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded">Hủy</button>
                                <button onClick={handleSaveSemester} className="px-4 py-2 bg-blue-600 text-white rounded">Lưu</button>
                            </div>
                        </div>
                    )}

                    {!selectedYear ? (
                        <div className="text-center py-12 text-gray-400">
                            <Calendar className="h-12 w-12 mx-auto mb-3 opacity-20" />
                            <p>Vui lòng chọn năm học từ danh sách bên trái</p>
                        </div>
                    ) : filteredSemesters.length === 0 ? (
                        <div className="text-center py-12 text-gray-400 border-2 border-dashed border-gray-100 rounded-xl">
                            <p>Chưa có học kỳ nào trong năm này</p>
                        </div>
                    ) : (
                        <div className="grid gap-4">
                            {filteredSemesters.map(sem => (
                                <div key={sem.id} className="bg-white border border-gray-200 p-4 rounded-xl flex justify-between items-center group hover:border-blue-200 hover:shadow-sm transition-all">
                                    <div className="flex items-center gap-4">
                                        <div className={`h-10 w-10 rounded-full flex items-center justify-center font-bold text-sm
                                            ${sem.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                                            {sem.semester_number}
                                        </div>
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <h3 className="font-semibold text-gray-800">{sem.name}</h3>
                                                {sem.is_active && <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded-full font-medium">Active</span>}
                                            </div>
                                            <p className="text-sm text-gray-500">{sem.code} • {sem.start_date} đến {sem.end_date}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        {!sem.is_active ? (
                                            <button
                                                onClick={() => handleActivateSemester(sem.id)}
                                                className="flex items-center gap-1 px-3 py-1 bg-white border border-gray-200 text-gray-500 hover:text-green-600 hover:border-green-200 hover:bg-green-50 rounded-lg text-xs font-medium transition-all shadow-sm"
                                                title="Đặt làm học kỳ hiện tại"
                                            >
                                                <Power className="h-3 w-3" /> Kích hoạt
                                            </button>
                                        ) : (
                                            <span className="flex items-center gap-1 px-3 py-1 bg-green-50 text-green-700 border border-green-100 rounded-lg text-xs font-medium shadow-sm">
                                                <CheckCircle className="h-3 w-3" /> Đang hoạt động
                                            </span>
                                        )}
                                        <div className="flex items-center border-l border-gray-200 ml-2 pl-2 gap-1">
                                            <button onClick={() => handleEditSemester(sem)} className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg" title="Sửa thông tin">
                                                <Edit2 className="h-4 w-4" />
                                            </button>
                                            <button onClick={() => handleDeleteSemester(sem.id)} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg" title="Xóa học kỳ">
                                                <Trash2 className="h-4 w-4" />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default AcademicManagement;
