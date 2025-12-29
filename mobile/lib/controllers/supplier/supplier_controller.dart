// lib/controllers/supplier/supplier_controller.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../apis/dtos/user/requests/update_profile_request.dart';
import '../../apis/helpers/api_exception.dart';
import '../../apis/resources/users/profile_api.dart';
import '../../models/producto_model.dart';
import '../../models/promocion_model.dart';
import '../../models/proveedor.dart';
import '../../services/auth/auth_service.dart';
import '../../services/productos/productos_service.dart';
import '../../services/proveedor/proveedor_service.dart';

/// Controller para gestionar la pantalla del proveedor
/// ✅ ACTUALIZADO: Manejo mejorado de errores 401
class SupplierController extends ChangeNotifier {
  final AuthService _authService;
  final ProveedorService _proveedorService;
  final ProfileApi _profileApi;
  final ProductosService _productosService = ProductosService();

  // ============================================
  // ESTADO PRINCIPAL
  // ============================================
  ProveedorModel? _proveedor;
  bool _loading = true;
  String? _error;
  bool _rolIncorrecto = false;

  // Estados secundarios para operaciones
  bool _actualizandoPerfil = false;
  bool _subiendoLogo = false;
  bool _actualizandoContacto = false;

  SupplierController({
    AuthService? authService,
    ProveedorService? proveedorService,
    ProfileApi? profileApi,
  }) : _authService = authService ?? AuthService(),
       _proveedorService = proveedorService ?? ProveedorService(),
       _profileApi = profileApi ?? ProfileApi();

  // ============================================
  // GETTERS - ESTADO PRINCIPAL
  // ============================================

  ProveedorModel? get proveedor => _proveedor;
  bool get loading => _loading;
  bool get verificado => _proveedor?.verificado ?? false;
  String? get error => _error;
  bool get rolIncorrecto => _rolIncorrecto;

  // ============================================
  // GETTERS - ESTADOS SECUNDARIOS
  // ============================================

  bool get actualizandoPerfil => _actualizandoPerfil;
  bool get subiendoLogo => _subiendoLogo;
  bool get actualizandoContacto => _actualizandoContacto;

  // ============================================
  // GETTERS - DATOS DEL PROVEEDOR
  // ============================================

  String get nombreNegocio => _proveedor?.nombre ?? '';
  String get email => _proveedor?.emailActual ?? '';
  String get ruc => _proveedor?.ruc ?? '';
  String get ciudad => _proveedor?.ciudad ?? '';
  String get direccion => _proveedor?.direccion ?? '';
  String? get logo => _proveedor?.logoUrlCompleta;
  String get tipoProveedor => _proveedor?.tipoProveedorDisplay ?? '';
  String get telefono => _proveedor?.celularActual ?? '';
  String get nombreCompleto => _proveedor?.nombreCompleto ?? '';

  // Horarios
  String? get horarioApertura => _proveedor?.horarioApertura;
  String? get horarioCierre => _proveedor?.horarioCierre;
  bool get estaAbierto => _proveedor?.estaAbierto ?? false;
  String? get horarioCompleto => _proveedor?.horarioCompleto;

  // Configuración
  bool get activo => _proveedor?.activo ?? false;
  double get comision => _proveedor?.comisionPorcentaje ?? 0.0;

  // Fechas
  DateTime? get fechaCreacion => _proveedor?.createdAt;
  DateTime? get ultimaActualizacion => _proveedor?.updatedAt;

  // ============================================
  // GETTERS - DATOS OPERACIONALES
  // ============================================

  final List<ProductoModel> _productos = [];
  final List<Map<String, dynamic>> _pedidosPendientes = [];
  final List<PromocionModel> _promociones = [];
  final Set<String> _logosCaidos = {};

  List<ProductoModel> get productos => _productos;
  List<Map<String, dynamic>> get pedidosPendientes => _pedidosPendientes;
  List<PromocionModel> get promociones => _promociones;
  int get totalProductos => _productos.length;
  int get pedidosPendientesCount => _pedidosPendientes.length;

  bool _procesandoProducto = false;
  bool _procesandoPromocion = false;

  bool get procesandoProducto => _procesandoProducto;
  bool get procesandoPromocion => _procesandoPromocion;

  // Estadísticas
  double get ventasHoy => 0.0;
  double get ventasMes => 0.0;
  int get pedidosCompletados => 0;
  double get valoracionPromedio => _proveedor?.calificacionPromedio ?? 0.0;
  int get totalResenas => _proveedor?.totalResenas ?? 0;

  // ============================================
  // MÉTODOS - CARGAR DATOS INICIALES
  // ============================================

  Future<void> cargarDatos() async {
    _loading = true;
    _error = null;
    _rolIncorrecto = false;
    notifyListeners();

    try {
      final rolUsuario = _authService.getRolCacheado()?.toUpperCase();
      debugPrint('🔍 Validando rol: $rolUsuario');

      if (rolUsuario != 'PROVEEDOR') {
        _rolIncorrecto = true;
        _error = 'Esta pantalla es solo para proveedores';
        _loading = false;
        debugPrint('Rol incorrecto: $rolUsuario');
        notifyListeners();
        return;
      }

      debugPrint('Cargando datos del proveedor...');
      _proveedor = await _proveedorService.obtenerMiProveedor();

      debugPrint('Proveedor cargado: ${_proveedor!.nombre}');
      await _cargarProductosProveedor();
      await _cargarPromocionesProveedor();
      _loading = false;
      _error = null;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'cargar_datos');
      _loading = false;
    } catch (e, stackTrace) {
      _error = 'Error al cargar información del proveedor';
      _loading = false;
      debugPrint('Error: $e\n$stackTrace');
    }

    notifyListeners();
  }

  // ============================================
  // MÉTODOS - ACTUALIZAR PERFIL (Negocio)
  // ============================================

  /// Actualiza datos del negocio: nombre, RUC, tipo, descripción, ubicación, horarios
  Future<bool> actualizarPerfil(Map<String, dynamic> datos) async {
    // Validar que no esté vacío
    if (datos.isEmpty) {
      _error = 'No hay datos para actualizar';
      notifyListeners();
      return false;
    }

    // Validar campos
    if (!_validarDatosPerfil(datos)) {
      notifyListeners();
      return false;
    }

    _actualizandoPerfil = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Actualizando perfil del negocio...');
      debugPrint('Datos a enviar: $datos');

      _proveedor = await _proveedorService.actualizarMiProveedor(datos);

      debugPrint('Perfil del negocio actualizado');
      _actualizandoPerfil = false;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'actualizar_perfil');
      _actualizandoPerfil = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _error = 'Error al actualizar perfil: $e';
      _actualizandoPerfil = false;
      debugPrint('Error: $e\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // MÉTODOS - ACTUALIZAR DATOS DE CONTACTO
  // ============================================

  /// Actualiza los datos de contacto del usuario asociado al proveedor
  Future<bool> actualizarDatosContacto({
    String? email,
    String? firstName,
    String? lastName,
    String? telefono,
  }) async {
    // Validar que al menos un campo esté presente
    if ((email == null || email.isEmpty) &&
        (firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty) &&
        (telefono == null || telefono.isEmpty)) {
      _error = 'Debes proporcionar al menos un dato de contacto';
      notifyListeners();
      return false;
    }

    _actualizandoContacto = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Actualizando mis datos de contacto...');
      debugPrint(
        'Email: $email, Nombre: $firstName, Apellido: $lastName, Teléfono: $telefono',
      );

      // Actualizar contacto usando el endpoint público
      // OPTIMIZACIÓN: Solo llamar si hay datos de perfil de usuario para editar
      if (email != null || firstName != null || lastName != null) {
        _proveedor = await _proveedorService.editarMiContacto(
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
      }

      // Actualizar teléfono si viene y es diferente
      if (telefono != null && telefono.isNotEmpty) {
        debugPrint('📱 Actualizando teléfono en perfil de usuario: $telefono');

        final request = UpdateProfileRequest(telefono: telefono);
        await _profileApi.updateProfile(request);

        // Recargar proveedor para reflejar celular_usuario actualizado
        _proveedor = await _proveedorService.obtenerMiProveedor();

        // DIAGNÓSTICO E/3: Verificación post-update y Prueba Definitiva
        // Si el backend devuelve el objeto actualizado, verificamos si el cambio se aplicó
        if (_proveedor?.celularActual != telefono) {
          debugPrint(
            '⚠️ ALERTA: El teléfono no se actualizó en la respuesta inmediata.',
          );
          debugPrint(
            'Valor esperado: $telefono | Valor recibido: ${_proveedor?.celularActual}',
          );
        } else {
          debugPrint('✅ Teléfono actualizado y verificado correctamente.');
        }
      }

      debugPrint('Datos de contacto actualizados correctamente');
      _actualizandoContacto = false;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'actualizar_contacto');
      _actualizandoContacto = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _error = 'Error al actualizar datos de contacto: $e';
      _actualizandoContacto = false;
      debugPrint('Error: $e\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // MÉTODOS - SUBIR LOGO
  // ============================================

  /// Sube el logo/imagen del proveedor
  Future<bool> subirLogo(File logoFile) async {
    // Validar que el archivo existe
    if (!logoFile.existsSync()) {
      _error = 'El archivo no existe';
      notifyListeners();
      return false;
    }

    // Validar tamaño (máximo 5 MB)
    final tamano = logoFile.lengthSync();
    const tamanoMaximo = 5 * 1024 * 1024;

    if (tamano > tamanoMaximo) {
      _error = 'El archivo es demasiado grande (máximo 5 MB)';
      notifyListeners();
      return false;
    }

    _subiendoLogo = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Subiendo logo...');
      debugPrint('Tamaño: ${(tamano / 1024 / 1024).toStringAsFixed(2)} MB');

      _proveedor = await _proveedorService.subirMiLogo(logoFile);

      debugPrint('Logo subido: ${_proveedor!.logoUrlCompleta}');
      final nuevoLogo = _proveedor?.logoUrlCompleta;
      if (nuevoLogo != null && nuevoLogo.isNotEmpty) {
        limpiarLogoCaido(nuevoLogo);
      }
      _subiendoLogo = false;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'subir_logo');
      _subiendoLogo = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _error = 'Error al subir logo: $e';
      _subiendoLogo = false;
      debugPrint('Error: $e\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // MÉTODOS PRIVADOS - VALIDACIÓN
  // ============================================

  bool _validarDatosPerfil(Map<String, dynamic> datos) {
    final camposValidos = {
      'nombre',
      'descripcion',
      'telefono',
      'direccion',
      'ciudad',
      'horarioApertura',
      'horarioCierre',
      'horario_apertura',
      'horario_cierre',
      'comisionPorcentaje',
      'tipo_proveedor',
      'tipoProveedor',
      'ruc',
    };

    // Validar que todos los campos sean válidos
    for (var key in datos.keys) {
      if (!camposValidos.contains(key)) {
        _error = 'Campo no válido: $key';
        return false;
      }
    }

    // Validar nombre no vacío
    if ((datos['nombre'] as String?)?.isEmpty ?? true) {
      _error = 'El nombre del negocio es requerido';
      return false;
    }

    // Validar RUC si viene en los datos
    if (datos.containsKey('ruc')) {
      final ruc = datos['ruc'] as String?;
      if (ruc != null && ruc.isEmpty) {
        _error = 'El RUC es requerido';
        return false;
      }
      if (ruc != null && ruc.length < 10) {
        _error = 'El RUC debe tener al menos 10 caracteres';
        return false;
      }
    }

    // Validar tipo de proveedor si viene en los datos
    if (datos.containsKey('tipo_proveedor')) {
      final tipo = datos['tipo_proveedor'] as String?;
      if (tipo == null || tipo.isEmpty) {
        _error = 'El tipo de proveedor es requerido';
        return false;
      }
    }

    return true;
  }

  // ============================================
  // MÉTODOS PRIVADOS - MANEJO DE ERRORES
  // ============================================

  ///  MEJORADO: Manejo contextual de errores 401
  void _handleApiException(ApiException e, {String? contexto}) {
    debugPrint('ApiException [${contexto ?? 'sin_contexto'}]: ${e.message}');
    debugPrint('Status: ${e.statusCode}');

    if (e.statusCode == 404) {
      if (e.errors['action'] == 'ROLE_RESET' ||
          e.details?['action'] == 'ROLE_RESET') {
        _rolIncorrecto = true;
        _error =
            'Tu perfil de proveedor ha sido desactivado. Se ha restablecido tu cuenta a Cliente.';
        // Intentar actualizar el rol en caché local implícitamente o sugerir relogin
        // Idealmente aquí podríamos forzar navegación, pero solo actualizamos estado
      } else {
        _rolIncorrecto = true;
        _error = 'No tienes proveedor vinculado';
      }
    } else if (e.statusCode == 401) {
      //  CORREGIDO: Mensaje claro sobre sesión expirada
      _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente';
      debugPrint('Sesión expirada - redirigir a login');
    } else if (e.statusCode == 403) {
      _error = 'No tienes permisos para realizar esta acción';
    } else if (e.statusCode == 400) {
      // El mensaje del backend suele ser descriptivo en errores 400
      _error = e.message.isNotEmpty
          ? e.message
          : 'Los datos proporcionados no son válidos';
    } else if (e.statusCode >= 500) {
      _error = 'Error en el servidor. Intenta nuevamente más tarde';
    } else {
      _error = e.message.isNotEmpty ? e.message : 'Ocurrió un error inesperado';
    }
  }

  // ============================================
  // MÉTODOS - UTILIDAD
  // ============================================

  /// Refresca todos los datos del proveedor
  Future<void> refrescar() async {
    await cargarDatos();
  }

  /// Refresca productos del proveedor
  Future<void> refrescarProductos() async {
    await _cargarProductosProveedor();
    await _cargarPromocionesProveedor();
    notifyListeners();
  }

  // ============================================================
  // PROMOCIONES (stubs sin endpoints de escritura)
  // ============================================================
  Future<bool> crearProducto(Map<String, dynamic> data, {File? imagen}) async {
    if (_proveedor == null) {
      _error = 'No se encontró tu perfil como proveedor';
      notifyListeners();
      return false;
    }

    _procesandoProducto = true;
    _error = null;
    notifyListeners();

    try {
      final producto = await _productosService.crearProducto(
        data,
        imagen: imagen,
      );
      _productos.insert(0, producto);
      _procesandoProducto = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'crear_producto');
    } catch (e) {
      _error = 'Error creando producto: $e';
    }
    _procesandoProducto = false;
    notifyListeners();
    return false;
  }

  Future<bool> crearPromocion(Map<String, dynamic> data, {File? imagen}) async {
    if (_proveedor == null) {
      _error = 'No se encontró tu perfil como proveedor';
      notifyListeners();
      return false;
    }

    _procesandoPromocion = true;
    _error = null;
    notifyListeners();

    try {
      final promocion = await _productosService.crearPromocion(
        data,
        imagen: imagen,
      );
      _promociones.insert(0, promocion);
      _procesandoPromocion = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'crear_promocion');
    } catch (e) {
      _error = 'Error creando promoción: $e';
    }
    _procesandoPromocion = false;
    notifyListeners();
    return false;
  }

  Future<bool> editarPromocion(
    int id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    if (_proveedor == null) {
      _error = 'No se encontró tu perfil como proveedor';
      notifyListeners();
      return false;
    }

    _procesandoPromocion = true;
    _error = null;
    notifyListeners();

    try {
      final promocion = await _productosService.actualizarPromocion(
        id,
        data,
        imagen: imagen,
      );
      // Actualizar en la lista local
      final index = _promociones.indexWhere((p) => p.id == id.toString());
      if (index >= 0) {
        _promociones[index] = promocion;
      }
      _procesandoPromocion = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiException(e, contexto: 'editar_promocion');
    } catch (e) {
      _error = 'Error editando promoción: $e';
    }
    _procesandoPromocion = false;
    notifyListeners();
    return false;
  }

  Future<bool> eliminarProducto(String id) async {
    _error = null;
    notifyListeners();
    try {
      await _productosService.eliminarProductoProveedor(id);
      _productos.removeWhere((producto) => producto.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar el producto';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarPromocion(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _productosService.eliminarPromocion(id);
      _promociones.removeWhere((promo) => promo.id == id.toString());
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar la promoción';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cambiarEstadoPromocion(int id, bool activa) async {
    _error = null;
    notifyListeners();
    try {
      final promocion = await _productosService.actualizarPromocion(id, {
        'activa': activa ? 'true' : 'false',
      });
      final index = _promociones.indexWhere(
        (promo) => promo.id == id.toString(),
      );
      if (index >= 0) {
        _promociones[index] = promocion;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar la promoción';
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión del usuario
  Future<bool> cerrarSesion() async {
    try {
      debugPrint('Cerrando sesión...');
      await _authService.logout();
      limpiar();
      debugPrint('Sesión cerrada');
      return true;
    } catch (e) {
      debugPrint('Error cerrando sesión: $e');
      _error = 'Error al cerrar sesión';
      notifyListeners();
      return false;
    }
  }

  /// Limpia el error actual
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void limpiar() {
    _proveedor = null;
    _productos.clear();
    _pedidosPendientes.clear();
    _promociones.clear();
    _logosCaidos.clear();
    _loading = false;
    _error = null;
    _rolIncorrecto = false;
    _actualizandoPerfil = false;
    _subiendoLogo = false;
    _actualizandoContacto = false;
    _procesandoProducto = false;
    _procesandoPromocion = false;
    notifyListeners();
  }

  bool esLogoCaido(String url) => _logosCaidos.contains(url);

  void marcarLogoCaido(String url) {
    if (_logosCaidos.add(url)) {
      notifyListeners();
    }
  }

  void limpiarLogoCaido(String url) {
    if (_logosCaidos.remove(url)) {
      notifyListeners();
    }
  }

  // ============================================================
  // CARGA DE PRODUCTOS DEL PROVEEDOR
  // ============================================================
  Future<void> _cargarProductosProveedor() async {
    if (_proveedor == null) return;
    try {
      final lista = await _productosService.obtenerProductos(
        proveedorId: _proveedor!.id.toString(),
      );
      _productos
        ..clear()
        ..addAll(lista);
    } catch (e) {
      debugPrint('Error cargando productos proveedor: $e');
      _error ??= 'No se pudieron cargar los productos';
    }
  }

  Future<void> _cargarPromocionesProveedor() async {
    if (_proveedor == null) return;
    try {
      final lista = await _productosService.obtenerPromocionesPorProveedor(
        _proveedor!.id.toString(),
      );
      final idProveedor = _proveedor!.id.toString();
      final soloMias = lista
          .where((p) => p.proveedorId == idProveedor)
          .toList();
      _promociones
        ..clear()
        ..addAll(soloMias);
    } catch (e) {
      debugPrint('Error cargando promociones proveedor: $e');
      _error ??= 'No se pudieron cargar las promociones';
    }
  }
}
