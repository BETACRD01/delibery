import React, { useEffect, useState } from "react";
import { solicitudesRolAPI } from "../../services/api";
import {
  Check,
  X,
  Loader2,
  UserCog,
  Trash2,
  AlertTriangle,
  RotateCcw,
  ArrowLeft
} from "lucide-react";

export function SolicitudesCambioRol() {
  const [solicitudes, setSolicitudes] = useState([]);
  const [detalle, setDetalle] = useState(null);
  const [loading, setLoading] = useState(true);
  const [, setProcesando] = useState(false);  // ← CORREGIDO: ya no genera warning
  const [error, setError] = useState("");

  // Modales
  const [modalAbierto, setModalAbierto] = useState(false);
  const [modalEliminar, setModalEliminar] = useState(false);
  const [tipoAccion, setTipoAccion] = useState(null);
  const [motivo, setMotivo] = useState("");
  const [confirmacionEliminar, setConfirmacionEliminar] = useState("");

  useEffect(() => {
    cargarSolicitudes();
  }, []);

  const cargarSolicitudes = async () => {
    try {
      setLoading(true);
      const res = await solicitudesRolAPI.adminListar();
      setSolicitudes(res.data.results || res.data);
      setError("");
    } catch (err) {
      console.error(err);
      setError("Error obteniendo solicitudes");
    } finally {
      setLoading(false);
    }
  };

  const verDetalle = async (sol) => {
    try {
      setDetalle(null);
      setError("");

      const res = await solicitudesRolAPI.adminDetalle(
        sol.id || sol.uuid || sol.pk
      );

      setDetalle(res.data);
    } catch (err) {
      console.error("Error cargando detalle:", err);
      const errorMsg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        "No se pudo cargar el detalle";

      setError(errorMsg);
    }
  };

  // Abrir modales
  const abrirModalAceptar = () => {
    setTipoAccion("aceptar");
    setMotivo("");
    setError("");
    setModalAbierto(true);
  };

  const abrirModalRechazar = () => {
    setTipoAccion("rechazar");
    setMotivo("");
    setError("");
    setModalAbierto(true);
  };

  const abrirModalRevertir = () => {
    setTipoAccion("revertir");
    setMotivo("");
    setError("");
    setModalAbierto(true);
  };

  const cerrarModal = () => {
    setModalAbierto(false);
    setTipoAccion(null);
    setMotivo("");
    setError("");
  };

  const abrirModalEliminar = () => {
    setConfirmacionEliminar("");
    setError("");
    setModalEliminar(true);
  };

  const cerrarModalEliminar = () => {
    setModalEliminar(false);
    setConfirmacionEliminar("");
    setError("");
  };

  // Confirmar acciones
  const confirmarAceptar = async () => {
    try {
      setProcesando(true);
      setError("");

      const data = {};
      if (motivo.trim()) data.motivo_respuesta = motivo.trim();

      await solicitudesRolAPI.aceptar(detalle.id, data);

      await cargarSolicitudes();
      setDetalle(null);
      cerrarModal();
    } catch (err) {
      console.error(err);
      const msg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        "No se pudo aceptar la solicitud";
      setError(msg);
    } finally {
      setProcesando(false);
    }
  };

  const confirmarRechazar = async () => {
    try {
     setProcesando(true);
      setError("");

      const data = {};
      if (motivo.trim()) data.motivo_respuesta = motivo.trim();

      await solicitudesRolAPI.rechazar(detalle.id, data);

      await cargarSolicitudes();
      setDetalle(null);
      cerrarModal();
    } catch (err) {
      console.error(err);
      const msg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        "No se pudo rechazar la solicitud";
      setError(msg);
    } finally {
      setProcesando(false);
    }
  };

  const confirmarRevertir = async () => {
    if (!motivo.trim() || motivo.trim().length < 10) {
      setError("El motivo debe tener mínimo 10 caracteres");
      return;
    }

    try {
      setProcesando(true);
      setError("");

      await solicitudesRolAPI.revertir(detalle.id, {
        motivo_reversion: motivo.trim()
      });

      await cargarSolicitudes();
      setDetalle(null);
      cerrarModal();
    } catch (err) {
      console.error(err);
      const msg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        "No se pudo revertir";
      setError(msg);
    } finally {
      setProcesando(false);
    }
  };

  const confirmarEliminar = async () => {
    if (confirmacionEliminar !== "ELIMINAR") {
      setError("Debes escribir ELIMINAR para confirmar");
      return;
    }

    try {
      setProcesando(true);
      setError("");

      await solicitudesRolAPI.eliminar(detalle.id);

      await cargarSolicitudes();
      setDetalle(null);
      cerrarModalEliminar();
    } catch (err) {
      console.error(err);
      const msg =
        err.response?.data?.error ||
        err.response?.data?.detail ||
        "No se pudo eliminar";
      setError(msg);
    } finally {
      setProcesando(false);
    }
  };

  if (loading)
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-12 h-12 text-blue-500 animate-spin" />
      </div>
    );

  return (
    <div className="bg-slate-950 min-h-screen py-10 px-4">
      <div className="max-w-7xl mx-auto">

        {/* BOTÓN REGRESAR */}
        <div className="mb-6">
          <button
            onClick={() => window.history.back()}
            className="flex items-center gap-2 px-4 py-2 bg-slate-800/60 border border-slate-700 text-slate-300 rounded-lg hover:bg-slate-800 hover:border-slate-500 transition"
          >
            <ArrowLeft size={18} />
            Regresar al Dashboard
          </button>
        </div>

        {/* TÍTULO */}
        <div className="flex items-center gap-3 mb-10">
          <div className="p-3 bg-blue-600/20 rounded-xl">
            <UserCog className="text-blue-400" size={30} />
          </div>
          <h1 className="text-3xl text-white font-bold">
            Solicitudes de Cambio de Rol
          </h1>
        </div>

        {/* Error global */}
        {error && !modalAbierto && !modalEliminar && (
          <div className="bg-red-500/10 border border-red-500/40 text-red-300 px-4 py-3 rounded-lg mb-6">
            ⚠️ {error}
          </div>
        )}

        {/* =================== GRID PRINCIPAL =================== */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">

          {/* ===================================
              LISTADO IZQUIERDO AGRUPADO
              =================================== */}
          <div className="space-y-10">

            {/* ================== PENDIENTES ================== */}
            <div>
              <h2 className="text-yellow-400 text-xl font-bold mb-3">
                🟡 Solicitudes Pendientes
              </h2>

              {solicitudes.filter(s => s.estado === "PENDIENTE").length === 0 ? (
                <p className="text-slate-500 text-sm">No hay pendientes.</p>
              ) : (
                <div className="space-y-4">
                  {solicitudes
                    .filter(s => s.estado === "PENDIENTE")
                    .map(s => (
                      <div
                        key={s.id}
                        onClick={() => verDetalle(s)}
                        className="bg-yellow-600/10 border border-yellow-500/30 p-5 rounded-xl hover:border-yellow-500/50 transition cursor-pointer"
                      >
                        <p className="text-white font-semibold">{s.usuario_nombre}</p>
                        <p className="text-slate-400 text-sm">{s.usuario_email}</p>
                        <p className="text-yellow-300 text-xs mt-1 font-bold">
                          Rol: {s.rol_solicitado?.toUpperCase()}
                        </p>
                      </div>
                    ))}
                </div>
              )}
            </div>

            {/* ================== ACEPTADAS ================== */}
            <div>
              <h2 className="text-green-400 text-xl font-bold mb-3">
                🟢 Solicitudes Aceptadas
              </h2>

              {solicitudes.filter(s => s.estado === "ACEPTADA").length === 0 ? (
                <p className="text-slate-500 text-sm">No hay aceptadas.</p>
              ) : (
                <div className="space-y-4">
                  {solicitudes
                    .filter(s => s.estado === "ACEPTADA")
                    .map(s => (
                      <div
                        key={s.id}
                        onClick={() => verDetalle(s)}
                        className="bg-green-600/10 border border-green-500/30 p-5 rounded-xl hover:border-green-500/50 transition cursor-pointer"
                      >
                        <p className="text-white font-semibold">{s.usuario_nombre}</p>
                        <p className="text-slate-400 text-sm">{s.usuario_email}</p>
                        <p className="text-green-300 text-xs mt-1 font-bold">
                          Rol: {s.rol_solicitado?.toUpperCase()}
                        </p>
                      </div>
                    ))}
                </div>
              )}
            </div>

            {/* ================== RECHAZADAS ================== */}
            <div>
              <h2 className="text-red-400 text-xl font-bold mb-3">
                🔴 Solicitudes Rechazadas
              </h2>

              {solicitudes.filter(s => s.estado === "RECHAZADA").length === 0 ? (
                <p className="text-slate-500 text-sm">No hay rechazadas.</p>
              ) : (
                <div className="space-y-4">
                  {solicitudes
                    .filter(s => s.estado === "RECHAZADA")
                    .map(s => (
                      <div
                        key={s.id}
                        onClick={() => verDetalle(s)}
                        className="bg-red-600/10 border border-red-500/30 p-5 rounded-xl hover:border-red-500/50 transition cursor-pointer"
                      >
                        <p className="text-white font-semibold">{s.usuario_nombre}</p>
                        <p className="text-slate-400 text-sm">{s.usuario_email}</p>
                        <p className="text-red-300 text-xs mt-1 font-bold">
                          Rol: {s.rol_solicitado?.toUpperCase()}
                        </p>
                      </div>
                    ))}
                </div>
              )}
            </div>

            {/* ================== REVERTIDAS ================== */}
            <div>
              <h2 className="text-purple-400 text-xl font-bold mb-3">
                🟣 Solicitudes Revertidas
              </h2>

              {solicitudes.filter(s => s.estado === "REVERTIDA").length === 0 ? (
                <p className="text-slate-500 text-sm">No hay revertidas.</p>
              ) : (
                <div className="space-y-4">
                  {solicitudes
                    .filter(s => s.estado === "REVERTIDA")
                    .map(s => (
                      <div
                        key={s.id}
                        onClick={() => verDetalle(s)}
                        className="bg-purple-600/10 border border-purple-500/30 p-5 rounded-xl hover:border-purple-500/50 transition cursor-pointer"
                      >
                        <p className="text-white font-semibold">{s.usuario_nombre}</p>
                        <p className="text-slate-400 text-sm">{s.usuario_email}</p>
                        <p className="text-purple-300 text-xs mt-1 font-bold">
                          Rol: {s.rol_solicitado?.toUpperCase()}
                        </p>
                      </div>
                    ))}
                </div>
              )}
            </div>

          </div>

          {/* PANEL DERECHO (DETALLE) */}
          <div>
            {!detalle ? (
              <div className="bg-slate-900/70 border border-slate-800 p-6 rounded-xl text-center">
                <p className="text-slate-500">Selecciona una solicitud para ver detalles</p>
              </div>
            ) : (
              <div className="bg-slate-900/70 border border-slate-800 p-6 rounded-xl">

                <h2 className="text-2xl font-bold text-white mb-4">Detalles de la Solicitud</h2>

                <div className="space-y-3 text-slate-300">
                  <p><strong className="text-white">Usuario:</strong> {detalle.usuario?.email}</p>
                  <p><strong className="text-white">Rol solicitado:</strong> {detalle.rol_solicitado?.toUpperCase()}</p>

                  {detalle.rol_anterior && (
                    <p>
                      <strong className="text-white">Rol anterior:</strong>{" "}
                      {detalle.rol_anterior?.toUpperCase()}
                    </p>
                  )}

                  <p>
                    <strong className="text-white">Motivo del usuario:</strong>
                    <br />
                    {detalle.motivo || "No proporcionado"}
                  </p>

                  <p>
                    <strong className="text-white">Estado:</strong>{" "}
                    {detalle.estado}
                  </p>

                  {detalle.motivo_respuesta && (
                    <p>
                      <strong className="text-white">Motivo respuesta:</strong>
                      <br />
                      {detalle.motivo_respuesta}
                    </p>
                  )}

                  {detalle.motivo_reversion && (
                    <p>
                      <strong className="text-white">Motivo reversión:</strong>
                      <br />
                      {detalle.motivo_reversion}
                    </p>
                  )}
                </div>

                {/* Botones del panel derecho */}
                <div className="flex flex-wrap gap-3 mt-6">

                  {detalle.estado === "PENDIENTE" && (
                    <>
                      <button
                        onClick={abrirModalAceptar}
                        className="px-4 py-2 bg-green-600/20 border border-green-500/40 text-green-300 rounded-lg"
                      >
                        <Check size={16} /> Aceptar
                      </button>

                      <button
                        onClick={abrirModalRechazar}
                        className="px-4 py-2 bg-red-600/20 border border-red-500/40 text-red-300 rounded-lg"
                      >
                        <X size={16} /> Rechazar
                      </button>
                    </>
                  )}

                  {detalle.estado === "ACEPTADA" && detalle.rol_anterior && (
                    <button
                      onClick={abrirModalRevertir}
                      className="px-4 py-2 bg-purple-600/20 border border-purple-500/40 text-purple-300 rounded-lg"
                    >
                      <RotateCcw size={16} /> Revertir
                    </button>
                  )}

                  <button
                    onClick={abrirModalEliminar}
                    className="px-4 py-2 bg-orange-600/20 border border-orange-500/40 text-orange-300 rounded-lg ml-auto"
                  >
                    <Trash2 size={16} /> Eliminar
                  </button>

                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* MODALES */}
      {modalAbierto && detalle && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl shadow-2xl max-w-2xl w-full max-h-screen overflow-y-auto">

            <div
              className={`p-6 border-b border-slate-700 ${
                tipoAccion === "aceptar"
                  ? "bg-green-900/30"
                  : tipoAccion === "rechazar"
                  ? "bg-red-900/30"
                  : "bg-purple-900/30"
              }`}
            >
              <div className="flex justify-between items-center">
                <h3 className="text-2xl font-bold text-white">
                  {tipoAccion === "aceptar" && "Aceptar Solicitud"}
                  {tipoAccion === "rechazar" && "Rechazar Solicitud"}
                  {tipoAccion === "revertir" && "Revertir Cambio"}
                </h3>

                <button
                  onClick={cerrarModal}
                  className="text-slate-400 hover:text-white"
                >
                  <X size={24} />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-6">
              <textarea
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                rows="5"
                placeholder="Escribe el motivo aquí..."
                className="w-full bg-slate-800 border border-slate-700 rounded-lg text-white p-4"
              />

              {error && (
                <div className="bg-red-500/10 border border-red-500/50 text-red-300 px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}
            </div>

            <div className="p-6 border-t border-slate-700 flex gap-3 bg-slate-800/50">
              <button
                onClick={cerrarModal}
                className="flex-1 bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 rounded-lg"
              >
                Cancelar
              </button>

              <button
                onClick={
                  tipoAccion === "aceptar"
                    ? confirmarAceptar
                    : tipoAccion === "rechazar"
                    ? confirmarRechazar
                    : confirmarRevertir
                }
                className="flex-1 bg-blue-600 hover:bg-blue-500 text-white px-4 py-3 rounded-lg"
              >
                Confirmar
              </button>
            </div>

          </div>
        </div>
      )}

      {/* MODAL ELIMINAR */}
      {modalEliminar && detalle && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border-2 border-orange-500/40 rounded-2xl max-w-xl w-full">

            <div className="bg-orange-900/50 border-b border-orange-500/40 p-6">
              <h3 className="text-2xl font-bold text-white">
                Eliminar Solicitud
              </h3>
              <p className="text-orange-300 mt-1">
                Esta acción NO se puede deshacer.
              </p>
            </div>

            <div className="p-6 space-y-4">
              <p className="text-slate-300">
                Para confirmar escribe: <strong className="text-orange-400">ELIMINAR</strong>
              </p>

              <input
                type="text"
                value={confirmacionEliminar}
                onChange={(e) => setConfirmacionEliminar(e.target.value.toUpperCase())}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg text-white px-4 py-3"
              />

              {error && (
                <div className="bg-red-500/10 border border-red-500/50 text-red-300 px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}
            </div>

            <div className="p-6 border-t border-slate-700 bg-slate-800/50 flex gap-3">
              <button
                onClick={cerrarModalEliminar}
                className="flex-1 bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 rounded-lg"
              >
                Cancelar
              </button>

              <button
                onClick={confirmarEliminar}
                disabled={confirmacionEliminar !== "ELIMINAR"}
                className="flex-1 bg-red-600 hover:bg-red-500 text-white px-4 py-3 rounded-lg disabled:opacity-50"
              >
                Eliminar
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
