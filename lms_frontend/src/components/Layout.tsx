import React, { useState, useEffect } from 'react';
import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LayoutDashboard, BookOpen, Users, GraduationCap, LogOut, User, Menu, Building2, Calendar, TrendingUp, FileText, DollarSign, ChevronLeft, ChevronRight, X } from 'lucide-react';
import clsx from 'clsx';

const Layout: React.FC = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();
    const [sidebarOpen, setSidebarOpen] = useState(() => {
        const saved = localStorage.getItem('sidebarOpen');
        return saved !== null ? JSON.parse(saved) : true;
    });
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    useEffect(() => {
        localStorage.setItem('sidebarOpen', JSON.stringify(sidebarOpen));
    }, [sidebarOpen]);

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const navItems = [
        { name: 'Tổng quan', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Quản lý học phần', path: '/courses', icon: BookOpen },
        { name: 'Giảng viên', path: '/lecturers', icon: Users },
        { name: 'Sinh viên', path: '/students', icon: GraduationCap },
    ];

    if (user?.role === 'dean') {
        navItems.push(
            { name: 'Quản lý năm học', path: '/academic-years', icon: Calendar },
            { name: 'Quản lý khoa/viện', path: '/departments', icon: Building2 },
            { name: 'Quản lý lớp học', path: '/classes', icon: Users },
            { name: 'Quản lý điểm', path: '/grades', icon: GraduationCap },
            { name: 'Kết quả học tập', path: '/academic-results', icon: TrendingUp },
            { name: 'Học phí', path: '/tuitions', icon: DollarSign },
            { name: 'Yêu cầu', path: '/reports', icon: FileText }
        );
    }

    return (
        <div className="flex h-screen bg-gray-50 font-sans">
            {/* Desktop Sidebar */}
            <div className={clsx(
                "hidden md:flex bg-white border-r border-gray-200 flex-col shadow-sm transition-all duration-300",
                sidebarOpen ? "w-72" : "w-20"
            )}>
                <div className="p-6 border-b border-gray-100">
                    <h1 className={clsx(
                        "text-xl font-bold text-gray-800 flex items-center gap-3 transition-all duration-300",
                        !sidebarOpen && "justify-center"
                    )}>
                        <div className="h-8 w-8 bg-blue-600 rounded-lg flex items-center justify-center text-white flex-shrink-0">
                            <GraduationCap className="h-5 w-5" />
                        </div>
                        {sidebarOpen && <span>Quản Lý Đào Tạo</span>}
                    </h1>
                </div>

                <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
                    {navItems.map((item) => {
                        const Icon = item.icon;
                        const isActive = location.pathname.startsWith(item.path);
                        return (
                            <Link
                                key={item.path}
                                to={item.path}
                                className={clsx(
                                    "flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group",
                                    isActive
                                        ? "bg-blue-50 text-blue-700 font-semibold"
                                        : "text-gray-600 hover:bg-gray-100 hover:text-gray-900",
                                    !sidebarOpen && "justify-center"
                                )}
                                title={!sidebarOpen ? item.name : undefined}
                            >
                                <Icon className={clsx("h-5 w-5 transition-colors flex-shrink-0", isActive ? "text-blue-600" : "text-gray-400 group-hover:text-gray-600")} />
                                {sidebarOpen && <span className="truncate">{item.name}</span>}
                            </Link>
                        );
                    })}
                </nav>

                <div className="p-4 border-t border-gray-100">
                    {sidebarOpen ? (
                        <>
                            <div className="bg-gray-50 rounded-xl p-4 mb-3 flex items-center gap-3">
                                <div className="w-10 h-10 rounded-full bg-white border border-gray-200 flex items-center justify-center text-gray-600 shadow-sm flex-shrink-0">
                                    <User className="h-5 w-5" />
                                </div>
                                <div className="overflow-hidden">
                                    <p className="text-sm font-bold text-gray-900 truncate">{user?.username || 'Admin'}</p>
                                    <p className="text-xs text-green-600 font-medium bg-green-100 px-2 py-0.5 rounded-full w-fit">Đang hoạt động</p>
                                </div>
                            </div>
                            <button
                                onClick={handleLogout}
                                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-gray-700 hover:bg-red-50 hover:text-red-600 rounded-xl transition-all duration-200 text-sm font-medium border border-transparent hover:border-red-100"
                            >
                                <LogOut className="h-4 w-4" />
                                Đăng xuất
                            </button>
                        </>
                    ) : (
                        <button
                            onClick={handleLogout}
                            className="w-full flex items-center justify-center p-3 text-gray-700 hover:bg-red-50 hover:text-red-600 rounded-xl transition-all duration-200"
                            title="Đăng xuất"
                        >
                            <LogOut className="h-5 w-5" />
                        </button>
                    )}
                </div>
            </div>

            {/* Mobile Sidebar Overlay */}
            {mobileMenuOpen && (
                <>
                    <div className="fixed inset-0 bg-black/50 z-40 md:hidden" onClick={() => setMobileMenuOpen(false)} />
                    <div className="fixed inset-y-0 left-0 w-72 bg-white z-50 md:hidden shadow-xl flex flex-col">
                        <div className="p-6 border-b border-gray-100 flex items-center justify-between">
                            <h1 className="text-xl font-bold text-gray-800 flex items-center gap-3">
                                <div className="h-8 w-8 bg-blue-600 rounded-lg flex items-center justify-center text-white">
                                    <GraduationCap className="h-5 w-5" />
                                </div>
                                <span>Quản Lý Đào Tạo</span>
                            </h1>
                            <button onClick={() => setMobileMenuOpen(false)} className="p-2 hover:bg-gray-100 rounded-lg">
                                <X className="h-5 w-5" />
                            </button>
                        </div>

                        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
                            {navItems.map((item) => {
                                const Icon = item.icon;
                                const isActive = location.pathname.startsWith(item.path);
                                return (
                                    <Link
                                        key={item.path}
                                        to={item.path}
                                        onClick={() => setMobileMenuOpen(false)}
                                        className={clsx(
                                            "flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group",
                                            isActive
                                                ? "bg-blue-50 text-blue-700 font-semibold"
                                                : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
                                        )}
                                    >
                                        <Icon className={clsx("h-5 w-5 transition-colors", isActive ? "text-blue-600" : "text-gray-400 group-hover:text-gray-600")} />
                                        {item.name}
                                    </Link>
                                );
                            })}
                        </nav>

                        <div className="p-4 border-t border-gray-100">
                            <div className="bg-gray-50 rounded-xl p-4 mb-3 flex items-center gap-3">
                                <div className="w-10 h-10 rounded-full bg-white border border-gray-200 flex items-center justify-center text-gray-600 shadow-sm">
                                    <User className="h-5 w-5" />
                                </div>
                                <div className="overflow-hidden">
                                    <p className="text-sm font-bold text-gray-900 truncate">{user?.username || 'Admin'}</p>
                                    <p className="text-xs text-green-600 font-medium bg-green-100 px-2 py-0.5 rounded-full w-fit">Đang hoạt động</p>
                                </div>
                            </div>
                            <button
                                onClick={handleLogout}
                                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-gray-700 hover:bg-red-50 hover:text-red-600 rounded-xl transition-all duration-200 text-sm font-medium border border-transparent hover:border-red-100"
                            >
                                <LogOut className="h-4 w-4" />
                                Đăng xuất
                            </button>
                        </div>
                    </div>
                </>
            )}

            {/* Main Content */}
            <div className="flex-1 flex flex-col overflow-hidden">
                <header className="bg-white/80 backdrop-blur-md sticky top-0 z-20 border-b border-gray-200 px-6 py-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <button
                            onClick={() => setMobileMenuOpen(true)}
                            className="md:hidden text-gray-500 hover:text-gray-700 p-2 hover:bg-gray-100 rounded-lg"
                        >
                            <Menu className="h-6 w-6" />
                        </button>
                        <button
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                            className="hidden md:block text-gray-500 hover:text-gray-700 p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                            {sidebarOpen ? <ChevronLeft className="h-5 w-5" /> : <ChevronRight className="h-5 w-5" />}
                        </button>
                        <h2 className="text-xl font-bold text-gray-800">
                            {navItems.find(i => location.pathname.startsWith(i.path))?.name || 'Tổng quan'}
                        </h2>
                    </div>
                    <div className="flex items-center gap-4">
                        <button className="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200 transition-colors">
                            <span className="sr-only">Thông báo</span>
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
                        </button>
                    </div>
                </header>
                <main className="flex-1 overflow-auto p-6 md:p-8">
                    <div className="max-w-7xl mx-auto">
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
};

export default Layout;
