import React, { useEffect, useState, useContext } from "react";
import { useNavigate } from "react-router-dom";
// 💡 CORRECCIÓN: Se usa usuariosAPI, que ahora tiene la función resetearPassword
import { usuariosAPI } from "../../services/api"; 
import { AuthContext } from "../../context/AuthContext";
import { ArrowLeft, KeyRound, Search, XCircle, CheckCircle2 } from "lucide-react";

export function GestionPasswordsUsuarios() {
  const navigate = useNavigate();
  const { user } = useContext(AuthContext);

  const [usuarios, setUsuarios] = useState([]);
  const [busqueda, setBusqueda] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadingChange, setLoadingChange] = useState(false);
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");

  const [usuarioSeleccionado, setUsuarioSeleccionado] = useState(null);
  const [password1, setPassword1] = useState("");
  const [password2, setPassword2] = useState("");
  const [formError, setFormError] = useState("");

  useEffect(() => {
    cargarUsuarios();
  }, []);

  const cargarUsuarios = async (query = "") => {
    try {
      setLoading(true);

      const params = {};
      if (query.trim() !== "") {
        params.search = query.trim();
      }

      // 💡 CORRECCIÓN: usuariosAPI.listarNormales (Endpoint para usuarios sin perfil especial)
      // Debe obtener la lista de usuarios normales, que está en el backend /admin/usuarios/normales/
      const res = await usuariosAPI.listarNormales(params);

      const results = Array.isArray(res.data?.results)
        ? res.data.results
        : Array.isArray(res.data)
        ? res.data // Si el backend no usa paginación y devuelve el array directo (como en el view que tienes)
        : [];

      setUsuarios(results);
      setError("");
    } catch (err) {
      console.error("Error cargando usuarios normales:", err);
      setUsuarios([]);
      setError("No se pudieron cargar los usuarios normales.");
    } finally {
      setLoading(false);
    }
  };

  const abrirModalCambio = (usuario) => {
    setUsuarioSeleccionado(usuario);
    setPassword1("");
    setPassword2("");
    setFormError("");
    setMensaje("");
  };

  const cerrarModalCambio = () => {
    setUsuarioSeleccionado(null);
    setPassword1("");
    setPassword2("");
    setFormError("");
    setMensaje("");
  };

  const handleBuscar = (e) => {
    e.preventDefault();
    cargarUsuarios(busqueda);
  };

  const validarPassword = () => {
    if (!password1 || !password2) {
      return "Debes completar ambos campos de contraseña.";
    }
    if (password1.length < 8) {
      return "La contraseña debe tener al menos 8 caracteres.";
    }
    if (password1 !== password2) {
      return "Las contraseñas no coinciden.";
    }
    return "";
  };

  const handleCambiarPassword = async (e) => {
    e.preventDefault();
    setFormError("");
    setMensaje("");

    const err = validarPassword();
    if (err) {
      setFormError(err);
      return;
    }

    if (!usuarioSeleccionado) return;

    try {
      setLoadingChange(true);

      // 💡 CORRECCIÓN CRÍTICA: Se llama a la función resetearPassword (POST a /admin/usuarios/{id}/resetear_password/)
      await usuariosAPI.resetearPassword(usuarioSeleccionado.id, {
        nueva_password: password1,
        confirmar_password: password2,
      });

      setMensaje("Contraseña actualizada correctamente.");
      cargarUsuarios(busqueda);

      setTimeout(() => {
        cerrarModalCambio();
      }, 1500);
    } catch (err) {
      console.error("Error cambiando contraseña:", err);
      const resp = err?.response?.data;

      setFormError(
        resp?.detail ||
          resp?.error ||
          // Mensaje específico del serializador del backend
          resp?.confirmar_password?.[0] ||
          "No se pudo cambiar la contraseña."
      );
    } finally {
      setLoadingChange(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950">
      <header className="bg-slate-900/70 backdrop-blur-xl border-b border-slate-800 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center gap-3">
          <button
            onClick={() => navigate("/dashboard")}
            className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>

          <h1 className="text-xl font-bold text-white flex items-center gap-2">
            <KeyRound className="w-6 h-6 text-blue-400" />
            Gestión de contraseñas
          </h1>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6">
        <form onSubmit={handleBuscar} className="flex gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Buscar usuario..."
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="w-full bg-slate-900/80 border border-slate-700 rounded-xl text-sm text-white px-9 py-2.5"
            />
          </div>
          <button className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl">
            Buscar
          </button>
        </form>

        {error && (
          <div className="bg-red-500/10 border border-red-500/40 text-red-300 px-4 py-3 rounded-xl mb-4">
            <XCircle className="w-4 h-4 inline mr-2" />
            {error}
          </div>
        )}

        {/* LISTA */}
        {loading && <p className="text-slate-400">Cargando usuarios...</p>}
        
        {!loading && usuarios.length === 0 && (
          <p className="text-sm text-slate-400">No se encontraron usuarios.</p>
        )}

        {!loading && usuarios.length > 0 && (
          <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-4">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-slate-400 text-xs uppercase border-b border-slate-800">
                  <th className="py-2 text-left px-2">Nombre</th>
                  <th className="text-left">Email</th>
                  <th>Estado</th>
                  <th>Último login</th>
                  <th className="text-right px-2">Acciones</th>
                </tr>
              </thead>

              <tbody>
                {usuarios.map((u) => (
                  <tr key={u.id} className="border-b border-slate-800/50">
                    <td className="py-3 text-slate-200 px-2">
                      {u.nombre_completo ||
                        `${u.first_name || ""} ${u.last_name || ""}`.trim() ||
                        "Sin nombre"}
                    </td>

                    <td className="text-slate-300">{u.email}</td>

                    <td>
                      {u.is_active ? (
                        <span className="text-emerald-300">Activo</span>
                      ) : (
                        <span className="text-red-300">Inactivo</span>
                      )}
                    </td>

                    <td className="text-slate-400 text-xs">
                      {u.last_login
                        ? new Date(u.last_login).toLocaleString()
                        : "Nunca"}
                    </td>

                    <td className="text-right px-2">
                      <button
                        type="button"
                        onClick={() => abrirModalCambio(u)}
                        className="px-3 py-1.5 bg-blue-600/20 hover:bg-blue-600/40 text-blue-200 rounded-lg text-xs"
                      >
                        <KeyRound className="w-3.5 h-3.5 inline mr-1" />
                        Cambiar contraseña
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>

      {/* MODAL */}
      {usuarioSeleccionado && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6">
            <button
              onClick={cerrarModalCambio}
              className="absolute right-3 top-3 text-slate-500"
            >
              <XCircle className="w-5 h-5" />
            </button>

            <h3 className="text-white text-lg font-semibold mb-2">
              Cambiar contraseña
            </h3>

            <p className="text-slate-400 text-xs mb-4">
              Usuario: <span className="text-white">{usuarioSeleccionado.email}</span>
            </p>

            {formError && (
              <div className="bg-red-500/10 border border-red-500/40 text-red-300 px-3 py-2 mb-3 rounded">
                <XCircle className="w-4 h-4 inline mr-2" />
                {formError}
              </div>
            )}

            {mensaje && (
              <div className="bg-emerald-500/10 border border-emerald-500/40 text-emerald-300 px-3 py-2 mb-3 rounded">
                <CheckCircle2 className="w-4 h-4 inline mr-2" />
                {mensaje}
              </div>
            )}

            <form onSubmit={handleCambiarPassword} className="space-y-3">
              <div>
                <label className="text-xs text-slate-300">Nueva contraseña</label>
                <input
                  type="password"
                  value={password1}
                  onChange={(e) => setPassword1(e.target.value)}
                  className="w-full bg-slate-900/80 border border-slate-700 rounded-lg text-sm text-white px-3 py-2 mt-1"
                />
              </div>

              <div>
                <label className="text-xs text-slate-300">Confirmar contraseña</label>
                <input
                  type="password"
                  value={password2}
                  onChange={(e) => setPassword2(e.target.value)}
                  className="w-full bg-slate-900/80 border border-slate-700 rounded-lg text-sm text-white px-3 py-2 mt-1"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={cerrarModalCambio}
                  className="px-3 py-1.5 text-xs border border-slate-700 rounded-lg text-slate-300"
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs bg-blue-600 hover:bg-blue-500 text-white rounded-lg"
                  disabled={loadingChange}
                >
                  {loadingChange ? "Guardando..." : "Guardar"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}