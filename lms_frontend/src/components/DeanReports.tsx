import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { FileText, Filter, Eye, CheckCircle, XCircle, Clock, AlertCircle } from 'lucide-react';

interface Report {
    id: number;
    student_code: string;
    student_name: string;
    title: string;
    description: string;
    report_type: string;
    status: string;
    dean_response: string | null;
    created_at: string;
    updated_at: string;
    resolved_at: string | null;
    resolved_by_name: string | null;
}

interface ReportStats {
    total: number;
    pending: number;
    processing: number;
    resolved: number;
    rejected: number;
}

const DeanReports: React.FC = () => {
    const [reports, setReports] = useState<Report[]>([]);
    const [stats, setStats] = useState<ReportStats | null>(null);
    const [loading, setLoading] = useState(false);
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [selectedReport, setSelectedReport] = useState<Report | null>(null);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [responseText, setResponseText] = useState('');
    const [newStatus, setNewStatus] = useState('');

    useEffect(() => {
        fetchReports();
        fetchStats();
    }, [statusFilter]);

    const fetchReports = async () => {
        setLoading(true);
        try {
            const params = statusFilter ? { status: statusFilter } : {};
            const res = await api.get('/reports/all', { params });
            setReports(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const fetchStats = async () => {
        try {
            const res = await api.get('/reports/stats');
            setStats(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    const handleViewDetail = async (reportId: number) => {
        try {
            const res = await api.get(`/reports/${reportId}`);
            setSelectedReport(res.data);
            setNewStatus(res.data.status);
            setResponseText(res.data.dean_response || '');
            setShowDetailModal(true);
        } catch (err) {
            console.error(err);
        }
    };

    const handleUpdateReport = async () => {
        if (!selectedReport) return;

        try {
            await api.put(`/reports/${selectedReport.id}`, {
                status: newStatus,
                dean_response: responseText
            });
            setShowDetailModal(false);
            fetchReports();
            fetchStats();
        } catch (err) {
            console.error(err);
        }
    };

    const getStatusBadge = (status: string) => {
        const styles = {
            pending: 'bg-yellow-100 text-yellow-700 border-yellow-300',
            processing: 'bg-blue-100 text-blue-700 border-blue-300',
            resolved: 'bg-green-100 text-green-700 border-green-300',
            rejected: 'bg-red-100 text-red-700 border-red-300'
        };

        const labels = {
            pending: 'Chờ xử lý',
            processing: 'Đang xử lý',
            resolved: 'Đã giải quyết',
            rejected: 'Từ chối'
        };

        return (
            <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${styles[status as keyof typeof styles]}`}>
                {labels[status as keyof typeof labels] || status}
            </span>
        );
    };

    const getTypeLabel = (type: string) => {
        const types = {
            academic: '📚 Học tập',
            administrative: '📋 Hành chính',
            technical: '💻 Kỹ thuật',
            other: '📌 Khác'
        };
        return types[type as keyof typeof types] || type;
    };

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            <div className="flex justify-between items-center">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Quản Lý Yêu Cầu</h2>
                    <p className="text-gray-500 text-sm">Xem và xử lý yêu cầu từ sinh viên</p>
                </div>
            </div>

            {stats && (
                <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
                    <div className="bg-white p-4 rounded-xl border border-gray-200">
                        <div className="flex items-center gap-3">
                            <FileText className="h-8 w-8 text-gray-600" />
                            <div>
                                <div className="text-2xl font-bold">{stats.total}</div>
                                <div className="text-xs text-gray-500">Tổng số</div>
                            </div>
                        </div>
                    </div>
                    <div className="bg-yellow-50 p-4 rounded-xl border border-yellow-200">
                        <div className="flex items-center gap-3">
                            <Clock className="h-8 w-8 text-yellow-600" />
                            <div>
                                <div className="text-2xl font-bold text-yellow-700">{stats.pending}</div>
                                <div className="text-xs text-yellow-600">Chờ xử lý</div>
                            </div>
                        </div>
                    </div>
                    <div className="bg-blue-50 p-4 rounded-xl border border-blue-200">
                        <div className="flex items-center gap-3">
                            <AlertCircle className="h-8 w-8 text-blue-600" />
                            <div>
                                <div className="text-2xl font-bold text-blue-700">{stats.processing}</div>
                                <div className="text-xs text-blue-600">Đang xử lý</div>
                            </div>
                        </div>
                    </div>
                    <div className="bg-green-50 p-4 rounded-xl border border-green-200">
                        <div className="flex items-center gap-3">
                            <CheckCircle className="h-8 w-8 text-green-600" />
                            <div>
                                <div className="text-2xl font-bold text-green-700">{stats.resolved}</div>
                                <div className="text-xs text-green-600">Đã giải quyết</div>
                            </div>
                        </div>
                    </div>
                    <div className="bg-red-50 p-4 rounded-xl border border-red-200">
                        <div className="flex items-center gap-3">
                            <XCircle className="h-8 w-8 text-red-600" />
                            <div>
                                <div className="text-2xl font-bold text-red-700">{stats.rejected}</div>
                                <div className="text-xs text-red-600">Từ chối</div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100">
                <div className="p-4 border-b flex items-center gap-3">
                    <Filter className="h-5 w-5 text-gray-600" />
                    <select
                        className="px-4 py-2 border rounded-lg"
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                    >
                        <option value="">Tất cả</option>
                        <option value="pending">Chờ xử lý</option>
                        <option value="processing">Đang xử lý</option>
                        <option value="resolved">Đã giải quyết</option>
                        <option value="rejected">Từ chối</option>
                    </select>
                </div>

                {loading ? (
                    <div className="p-12 text-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                    </div>
                ) : (
                    <table className="w-full">
                        <thead className="bg-gray-50 text-xs uppercase text-gray-700">
                            <tr>
                                <th className="px-6 py-4 text-left">ID</th>
                                <th className="px-6 py-4 text-left">Sinh viên</th>
                                <th className="px-6 py-4 text-left">Tiêu đề</th>
                                <th className="px-6 py-4 text-center">Loại</th>
                                <th className="px-6 py-4 text-center">Trạng thái</th>
                                <th className="px-6 py-4 text-center">Ngày tạo</th>
                                <th className="px-6 py-4 text-center">Thao tác</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {reports.map(report => (
                                <tr key={report.id} className="hover:bg-blue-50/50 transition-colors">
                                    <td className="px-6 py-4 font-mono text-sm">#{report.id}</td>
                                    <td className="px-6 py-4">
                                        <div className="font-semibold">{report.student_name}</div>
                                        <div className="text-xs text-gray-500">{report.student_code}</div>
                                    </td>
                                    <td className="px-6 py-4 max-w-xs truncate">{report.title}</td>
                                    <td className="px-6 py-4 text-center text-sm">{getTypeLabel(report.report_type)}</td>
                                    <td className="px-6 py-4 text-center">{getStatusBadge(report.status)}</td>
                                    <td className="px-6 py-4 text-center text-sm text-gray-600">
                                        {new Date(report.created_at).toLocaleDateString('vi-VN')}
                                    </td>
                                    <td className="px-6 py-4 text-center">
                                        <button
                                            onClick={() => handleViewDetail(report.id)}
                                            className="px-3 py-1 bg-blue-500 text-white rounded-lg hover:bg-blue-600 text-sm flex items-center gap-2 mx-auto"
                                        >
                                            <Eye className="h-4 w-4" />
                                            Xem
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {showDetailModal && selectedReport && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-2xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                        <div className="p-6 border-b">
                            <h3 className="text-xl font-bold">Chi tiết yêu cầu #{selectedReport.id}</h3>
                        </div>
                        <div className="p-6 space-y-4">
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Sinh viên</label>
                                <p>{selectedReport.student_name} ({selectedReport.student_code})</p>
                            </div>
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Tiêu đề</label>
                                <p>{selectedReport.title}</p>
                            </div>
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Loại</label>
                                <p>{getTypeLabel(selectedReport.report_type)}</p>
                            </div>
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Mô tả</label>
                                <p className="whitespace-pre-wrap bg-gray-50 p-4 rounded-lg">{selectedReport.description}</p>
                            </div>
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Trạng thái</label>
                                <select
                                    className="w-full mt-2 px-4 py-2 border rounded-lg"
                                    value={newStatus}
                                    onChange={(e) => setNewStatus(e.target.value)}
                                >
                                    <option value="pending">Chờ xử lý</option>
                                    <option value="processing">Đang xử lý</option>
                                    <option value="resolved">Đã giải quyết</option>
                                    <option value="rejected">Từ chối</option>
                                </select>
                            </div>
                            <div>
                                <label className="text-sm font-semibold text-gray-700">Phản hồi</label>
                                <textarea
                                    className="w-full mt-2 px-4 py-2 border rounded-lg"
                                    rows={4}
                                    value={responseText}
                                    onChange={(e) => setResponseText(e.target.value)}
                                    placeholder="Nhập phản hồi cho sinh viên..."
                                />
                            </div>
                        </div>
                        <div className="p-6 border-t flex gap-3 justify-end">
                            <button
                                onClick={() => setShowDetailModal(false)}
                                className="px-4 py-2 border rounded-lg hover:bg-gray-50"
                            >
                                Hủy
                            </button>
                            <button
                                onClick={handleUpdateReport}
                                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
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

export default DeanReports;
