import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { Navbar } from './components/Navbar';
import { HomePage } from './pages/HomePage';
import { LoginPage } from './pages/LoginPage';
import { RegisterPage } from './pages/RegisterPage';
import { UsersPage } from './pages/UsersPage';

export default function App() {
  return (
    <Router>
      <AuthProvider>
        <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900">
          <Navbar />
          <main className="flex-1">
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/signup" element={<RegisterPage />} />
              <Route path="/departments" element={<Navigate to="/" replace />} />
              <Route path="/users" element={<UsersPage />} />
            </Routes>
          </main>
          <footer className="bg-white border-t border-slate-200 py-6 text-center text-xs text-slate-500">
            ProjectVault &copy; {new Date().getFullYear()} Academic Repository System — Powered by Spring Boot & React
          </footer>
        </div>
      </AuthProvider>
    </Router>
  );
}
