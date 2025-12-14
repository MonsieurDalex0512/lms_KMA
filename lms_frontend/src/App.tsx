import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Courses from './pages/Courses';
import DeanDepartments from './components/DeanDepartments';
import DeanClasses from './components/DeanClasses';
import DeanGrades from './components/DeanGrades';
import Lecturers from './pages/Lecturers';
import Students from './pages/Students';
import ClassDetails from './pages/ClassDetails';
import AcademicManagement from './pages/AcademicManagement';
import DeanAcademicResults from './components/DeanAcademicResults';
import DeanReports from './components/DeanReports';
import DeanTuition from './components/DeanTuition';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) return <div>Loading...</div>;
  if (!isAuthenticated) return <Navigate to="/login" />;
  return <>{children}</>;
};

const App: React.FC = () => {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="courses" element={<Courses />} />
            <Route path="departments" element={<DeanDepartments />} />
            <Route path="classes" element={<DeanClasses />} />
            <Route path="classes/:id" element={<ClassDetails />} />
            <Route path="grades" element={<DeanGrades />} />
            <Route path="lecturers" element={<Lecturers />} />
            <Route path="students" element={<Students />} />
            <Route path="academic-years" element={<AcademicManagement />} />
            <Route path="academic-results" element={<DeanAcademicResults />} />
            <Route path="reports" element={<DeanReports />} />
            <Route path="tuitions" element={<DeanTuition />} />
          </Route>
        </Routes>
      </AuthProvider>
    </Router>
  );
};

export default App;
