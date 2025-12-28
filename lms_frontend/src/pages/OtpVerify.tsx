import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { useNavigate, useLocation } from 'react-router-dom';
import { Shield, RefreshCw } from 'lucide-react';

interface LocationState {
    username: string;
    emailHint: string;
    message: string;
}

const OtpVerify: React.FC = () => {
    const [otp, setOtp] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [otpMessage, setOtpMessage] = useState('');
    const [resendCooldown, setResendCooldown] = useState(60);
    const [username, setUsername] = useState('');
    const [emailHint, setEmailHint] = useState('');
    const [isReady, setIsReady] = useState(false);
    const initRef = useRef(false);

    const { login } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    useEffect(() => {
        if (initRef.current) return;
        initRef.current = true;

        const state = location.state as LocationState | null;

        if (state?.username) {
            setUsername(state.username);
            setEmailHint(state.emailHint || '');
            setOtpMessage(state.message || 'OTP đã được gửi đến email của bạn');
            sessionStorage.setItem('otp_username', state.username);
            sessionStorage.setItem('otp_emailHint', state.emailHint || '');
            setIsReady(true);
        } else {
            const savedUsername = sessionStorage.getItem('otp_username');
            const savedEmailHint = sessionStorage.getItem('otp_emailHint');

            if (savedUsername) {
                setUsername(savedUsername);
                setEmailHint(savedEmailHint || '');
                setOtpMessage('Vui lòng nhập mã OTP');
                setIsReady(true);
            } else {
                navigate('/login', { replace: true });
            }
        }
    }, []);

    useEffect(() => {
        if (resendCooldown > 0) {
            const timer = setTimeout(() => setResendCooldown(resendCooldown - 1), 1000);
            return () => clearTimeout(timer);
        }
    }, [resendCooldown]);

    const handleOtpSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            const response = await api.post('/auth/verify-otp', {
                username: username,
                otp: otp
            });

            const { access_token, role } = response.data;
            sessionStorage.removeItem('otp_username');
            sessionStorage.removeItem('otp_emailHint');
            login(access_token, { username, role });
            navigate('/dashboard');
        } catch (err: any) {
            const errorMessage = err.response?.data?.detail || 'Mã OTP không hợp lệ';
            setError(errorMessage);
            setOtp('');
        } finally {
            setIsLoading(false);
        }
    };

    const handleResendOtp = async () => {
        if (resendCooldown > 0) return;

        setError('');
        setIsLoading(true);

        try {
            const response = await api.post('/auth/resend-otp', new URLSearchParams({
                username: username,
            }), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            });

            setOtpMessage(response.data.message || 'OTP mới đã được gửi');
            setResendCooldown(60);
            setOtp('');
            setError('');
        } catch (err: any) {
            setError(err.response?.data?.detail || 'Không thể gửi lại OTP');
        } finally {
            setIsLoading(false);
        }
    };

    const handleBackToLogin = () => {
        sessionStorage.removeItem('otp_username');
        sessionStorage.removeItem('otp_emailHint');
        navigate('/login');
    };

    if (!isReady) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 to-blue-100">
                <div className="text-gray-500">Đang tải...</div>
            </div>
        );
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 to-blue-100 p-4">
            <div className="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md border border-white/50 backdrop-blur-sm">
                <div className="text-center mb-8">
                    <div className="h-14 w-14 bg-gradient-to-tr from-green-500 to-emerald-600 rounded-2xl mx-auto flex items-center justify-center mb-4 shadow-lg shadow-green-500/30">
                        <Shield className="h-7 w-7 text-white" />
                    </div>
                    <h2 className="text-2xl font-bold text-gray-900">Xác Thực OTP</h2>
                    <p className="text-gray-500 text-sm mt-2">
                        Mã xác thực đã được gửi đến: <span className="font-semibold text-blue-600">{emailHint}</span>
                    </p>
                </div>

                {otpMessage && !error && (
                    <div className="bg-green-50 border border-green-100 text-green-600 p-3 rounded-xl mb-6 text-sm flex items-center gap-2">
                        <span className="text-lg">✉️</span> {otpMessage}
                    </div>
                )}

                {error && (
                    <div className="bg-red-50 border border-red-100 text-red-600 p-3 rounded-xl mb-6 text-sm flex items-center gap-2">
                        <span className="text-lg">⚠️</span> {error}
                    </div>
                )}

                <form onSubmit={handleOtpSubmit} className="space-y-5">
                    <div>
                        <label className="block text-gray-700 text-sm font-semibold mb-2 ml-1">Mã OTP (6 số)</label>
                        <div className="relative group">
                            <Shield className="absolute left-3 top-3 h-5 w-5 text-gray-400 group-focus-within:text-green-500 transition-colors" />
                            <input
                                type="text"
                                value={otp}
                                onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                                className="pl-10 w-full p-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all bg-gray-50 focus:bg-white placeholder-gray-400 text-center text-2xl tracking-[0.5em] font-mono"
                                placeholder="000000"
                                maxLength={6}
                                required
                                autoFocus
                            />
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading || otp.length !== 6}
                        className="w-full bg-gradient-to-r from-green-500 to-emerald-600 text-white p-3 rounded-xl hover:shadow-lg hover:shadow-green-500/30 transition-all duration-200 font-semibold text-sm active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {isLoading ? 'Đang xác thực...' : 'Xác Nhận OTP'}
                    </button>

                    <div className="flex items-center justify-between pt-2">
                        <button
                            type="button"
                            onClick={handleBackToLogin}
                            className="text-gray-500 hover:text-gray-700 text-sm flex items-center gap-1"
                        >
                            ← Quay lại đăng nhập
                        </button>

                        <button
                            type="button"
                            onClick={handleResendOtp}
                            disabled={resendCooldown > 0 || isLoading}
                            className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            <RefreshCw className={`h-4 w-4 ${isLoading && resendCooldown === 0 ? 'animate-spin' : ''}`} />
                            {resendCooldown > 0 ? `Gửi lại (${resendCooldown}s)` : 'Gửi lại OTP'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default OtpVerify;
