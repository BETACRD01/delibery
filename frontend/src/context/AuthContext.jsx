import React, { createContext, useState, useCallback, useEffect } from "react";
import { authAPI } from "../services/api";

export const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // ============================
  //   CARGAR USUARIO AL INICIAR
  // ============================
  useEffect(() => {
    const token = localStorage.getItem("access_token");
    if (token) {
      verificarToken();
    } else {
      setLoading(false);
    }
  }, []); // ← Solo una vez

  // ============================
  //     VERIFICAR TOKEN
  // ============================
  const verificarToken = useCallback(async () => {
    try {
      const response = await authAPI.perfil();

      // El backend devuelve "usuario" o el perfil directo
      const data = response.data.usuario || response.data;

      // Guardamos TODA la info, incluyendo rol
      setUser({
        nombre: data.nombre,
        email: data.email,
        rol: data.rol || data.rol_activo || data.roles?.[0] || "ADMIN",
        roles: data.roles || [],
        permisos: data.permisos || [],
        is_superuser: data.is_superuser,
      });

      setError(null);
    } catch (err) {
      console.error("Error verificando token:", err);

      localStorage.removeItem("access_token");
      localStorage.removeItem("refresh_token");
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  // ============================
  //            LOGIN
  // ============================
  const login = useCallback(
    async (email, password) => {
      try {
        setLoading(true);
        setError(null);

        const response = await authAPI.login(email, password);
        const { tokens } = response.data;

        if (tokens?.access && tokens?.refresh) {
          localStorage.setItem("access_token", tokens.access);
          localStorage.setItem("refresh_token", tokens.refresh);

          await verificarToken();
          return { success: true };
        } else {
          const msg = "Backend no envió tokens";
          setError(msg);
          return { success: false, error: msg };
        }
      } catch (err) {
        const msg =
          err.response?.data?.detail ||
          err.response?.data?.error ||
          "Error al iniciar sesión";

        setError(msg);
        return { success: false, error: msg };
      } finally {
        setLoading(false);
      }
    },
    [verificarToken]
  );

  // ============================
  //           LOGOUT
  // ============================
  const logout = useCallback(async () => {
    try {
      await authAPI.logout();
    } catch (err) {
      console.warn("Error en logout:", err);
    } finally {
      localStorage.removeItem("access_token");
      localStorage.removeItem("refresh_token");
      setUser(null);
      setError(null);
    }
  }, []);

  // ============================
  //      PROTECCIÓN ADMIN
  // ============================
  const isAuthenticated = !!user;

  const isAdmin =
    user?.is_superuser === true ||
    user?.rol === "ADMIN" ||
    user?.rol === "ADMINISTRADOR" ||
    user?.roles?.includes("ADMIN") ||
    user?.roles?.includes("ADMINISTRADOR");

  // ============================
  //       EXPORTAR CONTEXTO
  // ============================
  const value = {
    user,
    loading,
    error,
    login,
    logout,
    isAuthenticated,
    isAdmin,
    verificarToken,
  };

  return (
    <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
  );
}
