import React, { useContext } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";

import { AuthProvider, AuthContext } from "./context/AuthContext";

import { Login } from "./pages/auth/Login";
import { Dashboard } from "./pages/admin/Dashboard";
import { SolicitudesCambioRol } from "./pages/admin/SolicitudesCambioRol";
import { GestionPasswordsUsuarios } from "./pages/admin/GestionPasswordsUsuarios";

// 🔥 IMPORTS CORREGIDOS PARA LINUX (minúsculas)
import Pendientes from "./pages/admin/solicitudes/pendientes.jsx";
import Aceptadas from "./pages/admin/solicitudes/aceptadas.jsx";
import Rechazadas from "./pages/admin/solicitudes/rechazadas.jsx";
import Revertidas from "./pages/admin/solicitudes/revertidas.jsx";

import "./index.css";

function ProtectedRoute({ children }) {
  const { isAuthenticated, isAdmin, loading } = useContext(AuthContext);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <p className="text-slate-400 text-lg">Cargando...</p>
      </div>
    );
  }

  if (!isAuthenticated) return <Navigate to="/login" replace />;

  if (!isAdmin) {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-950">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white">Acceso denegado</h1>
          <p className="text-slate-400 mt-2">
            Solo administradores pueden acceder a esta sección.
          </p>
        </div>
      </div>
    );
  }

  return children;
}

function AppContent() {
  return (
    <Routes>
      {/* LOGIN */}
      <Route path="/login" element={<Login />} />

      {/* DASHBOARD */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />

      {/* SUB-PÁGINAS DE SOLICITUDES */}
      <Route
        path="/admin/solicitudes/pendientes"
        element={<Pendientes />}
      />
      <Route
        path="/admin/solicitudes/aceptadas"
        element={<Aceptadas />}
      />
      <Route
        path="/admin/solicitudes/rechazadas"
        element={<Rechazadas />}
      />
      <Route
        path="/admin/solicitudes/revertidas"
        element={<Revertidas />}
      />

      {/* PÁGINA PRINCIPAL DEL MÓDULO */}
      <Route
        path="/admin/solicitudes"
        element={
          <ProtectedRoute>
            <SolicitudesCambioRol />
          </ProtectedRoute>
        }
      />

      {/* MODULO PASSWORDS */}
      <Route
        path="/admin/usuarios/passwords"
        element={
          <ProtectedRoute>
            <GestionPasswordsUsuarios />
          </ProtectedRoute>
        }
      />

      {/* REDIRECCIONES */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <Router>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </Router>
  );
}
