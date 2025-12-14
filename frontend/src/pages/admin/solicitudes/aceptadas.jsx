import React, { useEffect, useState } from "react";
import { solicitudesRolAPI } from "../../../services/api";
import { ArrowLeft } from "lucide-react";

export default function Aceptadas() {
  const [solicitudes, setSolicitudes] = useState([]);

  useEffect(() => {
    solicitudesRolAPI.adminListar().then((res) => {
      setSolicitudes(res.data.results || res.data);
    });
  }, []);

  return (
    <div className="bg-slate-950 min-h-screen p-6 text-white">
      <button
        onClick={() => window.history.back()}
        className="flex items-center gap-2 px-4 py-2 bg-slate-800/60 rounded-lg mb-6"
      >
        <ArrowLeft size={18} /> Regresar
      </button>

      <h1 className="text-3xl font-bold mb-6 text-green-400">
        🟢 Solicitudes Aceptadas
      </h1>

      <div className="space-y-4">
        {solicitudes
          .filter((s) => s.estado === "ACEPTADA")
          .map((s) => (
            <div
              key={s.id}
              className="bg-green-600/10 border border-green-500/30 p-5 rounded-xl"
            >
              <p className="font-semibold">{s.usuario_nombre}</p>
              <p className="text-slate-400 text-sm">{s.usuario_email}</p>
              <p className="text-green-300 text-xs font-bold mt-1">
                Rol: {s.rol_solicitado?.toUpperCase()}
              </p>
            </div>
          ))}
      </div>
    </div>
  );
}
