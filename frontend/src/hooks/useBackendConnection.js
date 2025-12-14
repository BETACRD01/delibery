import { useState, useEffect } from "react";
import api from "../services/api";

export default function useBackendConnection() {
  const [checking, setChecking] = useState(true);
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState(null);

  const verificarConexion = async () => {
    try {
      const response = await api.get("/health/");

      if (response.status === 200) {
        setConnected(true);
        setError(null);
        return true;
      }

      setConnected(false);
      setError("Backend no respondió correctamente");
      return false;
    } catch (err) {
      setConnected(false);
      setError("No se pudo conectar al backend");
      return false;
    }
  };

  useEffect(() => {
    const check = async () => {
      setChecking(true);
      await verificarConexion();
      setChecking(false);
    };

    check();

    const interval = setInterval(check, 15000);
    return () => clearInterval(interval);
  }, []);

  return { checking, connected, error, verificarConexion };
}
