import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Users, GraduationCap, BookOpen, School, TrendingUp } from 'lucide-react';
import { BarChart, Bar, PieChart, Pie, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';

interface Statistics {
    total_students: number;
    total_lecturers: number;
    total_courses: number;
    total_classes: number;
    total_departments: number;
}

interface ChartData {
    students_by_department: Array<{ name: string; value: number }>;
    classes_by_semester: Array<{ semester: string; count: number }>;
    overview_comparison: Array<{ category: string; value: number }>;
}

const Dashboard: React.FC = () => {
    const [stats, setStats] = useState<Statistics | null>(null);
    const [chartData, setChartData] = useState<ChartData | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const [statsRes, chartsRes] = await Promise.all([
                api.get('/deans/statistics'),
                api.get('/deans/statistics/charts')
            ]);
            setStats(statsRes.data);
            setChartData(chartsRes.data);
        } catch (err) {
            console.error('Failed to fetch data:', err);
        } finally {
            setLoading(false);
        }
    };

    const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

    const StatCard = ({
        title,
        value,
        icon: Icon,
        bgColor,
        iconColor
    }: {
        title: string;
        value: number;
        icon: any;
        bgColor: string;
        iconColor: string;
    }) => (
        <div className={`${bgColor} p-6 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1`}>
            <div className="flex justify-between items-start">
                <div>
                    <p className="text-white/80 text-sm font-medium mb-2">{title}</p>
                    <h3 className="text-4xl font-bold text-white">{value}</h3>
                </div>
                <div className={`${iconColor} p-4 rounded-xl bg-white/20 backdrop-blur-sm`}>
                    <Icon className="h-8 w-8 text-white" />
                </div>
            </div>
        </div>
    );

    if (loading) {
        return (
            <div className="flex justify-center items-center h-64">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-in fade-in duration-500">
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard
                    title="Tổng Sinh Viên"
                    value={stats?.total_students || 0}
                    icon={Users}
                    bgColor="bg-gradient-to-br from-green-500 to-green-600"
                    iconColor="text-green-600"
                />
                <StatCard
                    title="Tổng Giảng Viên"
                    value={stats?.total_lecturers || 0}
                    icon={GraduationCap}
                    bgColor="bg-gradient-to-br from-indigo-500 to-indigo-600"
                    iconColor="text-indigo-600"
                />
                <StatCard
                    title="Tổng Môn Học"
                    value={stats?.total_courses || 0}
                    icon={BookOpen}
                    bgColor="bg-gradient-to-br from-blue-500 to-blue-600"
                    iconColor="text-blue-600"
                />
                <StatCard
                    title="Tổng Lớp Học"
                    value={stats?.total_classes || 0}
                    icon={School}
                    bgColor="bg-gradient-to-br from-purple-500 to-purple-600"
                    iconColor="text-purple-600"
                />
            </div>

            {/* Charts Section */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Overview Comparison Bar Chart */}
                <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <div className="flex items-center gap-2 mb-4">
                        <TrendingUp className="h-5 w-5 text-blue-600" />
                        <h3 className="text-lg font-bold text-gray-800">So Sánh Tổng Quan</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={chartData?.overview_comparison || []}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="category" tick={{ fill: '#6b7280', fontSize: 12 }} />
                            <YAxis tick={{ fill: '#6b7280', fontSize: 12 }} />
                            <Tooltip
                                contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                                labelStyle={{ color: '#374151', fontWeight: 'bold' }}
                            />
                            <Bar dataKey="value" fill="#3b82f6" radius={[8, 8, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* Students by Department Pie Chart */}
                <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <div className="flex items-center gap-2 mb-4">
                        <Users className="h-5 w-5 text-green-600" />
                        <h3 className="text-lg font-bold text-gray-800">Sinh Viên Theo Khoa</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={300}>
                        <PieChart>
                            <Pie
                                data={chartData?.students_by_department || []}
                                cx="50%"
                                cy="50%"
                                labelLine={false}
                                label={({ name, percent }) => `${name}: ${((percent || 0) * 100).toFixed(0)}%`}
                                outerRadius={80}
                                fill="#8884d8"
                                dataKey="value"
                            >
                                {chartData?.students_by_department.map((_, index) => (
                                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                ))}
                            </Pie>
                            <Tooltip
                                contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                            />
                        </PieChart>
                    </ResponsiveContainer>
                </div>

                {/* Classes by Semester Line Chart */}
                <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 lg:col-span-2">
                    <div className="flex items-center gap-2 mb-4">
                        <School className="h-5 w-5 text-purple-600" />
                        <h3 className="text-lg font-bold text-gray-800">Xu Hướng Lớp Học Theo Học Kỳ</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={chartData?.classes_by_semester || []}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="semester" tick={{ fill: '#6b7280', fontSize: 12 }} />
                            <YAxis tick={{ fill: '#6b7280', fontSize: 12 }} />
                            <Tooltip
                                contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                                labelStyle={{ color: '#374151', fontWeight: 'bold' }}
                            />
                            <Legend />
                            <Line
                                type="monotone"
                                dataKey="count"
                                stroke="#8b5cf6"
                                strokeWidth={3}
                                dot={{ fill: '#8b5cf6', r: 6 }}
                                activeDot={{ r: 8 }}
                                name="Số lớp học"
                            />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <h3 className="text-lg font-bold text-gray-800 mb-4">Thống Kê Nhanh</h3>
                    <div className="space-y-3">
                        <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                            <span className="text-gray-600">Tổng Khoa/Viện</span>
                            <span className="font-bold text-gray-900">{stats?.total_departments || 0}</span>
                        </div>
                        <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                            <span className="text-gray-600">Trung bình SV/Lớp</span>
                            <span className="font-bold text-gray-900">
                                {stats?.total_classes ? Math.round((stats.total_students / stats.total_classes) * 10) / 10 : 0}
                            </span>
                        </div>
                    </div>
                </div>

                <div className="bg-gradient-to-br from-gray-50 to-gray-100 p-6 rounded-2xl border border-gray-200">
                    <h3 className="text-lg font-bold text-gray-800 mb-2">Hệ Thống Quản Lý</h3>
                    <p className="text-gray-600 text-sm mb-4">Khoa Công Nghệ Thông Tin</p>
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                        <div className="h-2 w-2 bg-green-500 rounded-full animate-pulse"></div>
                        <span>Hệ thống đang hoạt động</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
