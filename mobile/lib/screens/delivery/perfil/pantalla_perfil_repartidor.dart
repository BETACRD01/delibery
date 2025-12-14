// lib/screens/delivery/perfil/pantalla_editar_perfil_repartidor.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/repartidor_service.dart';
import '../../../services/repartidor_datos_bancarios_service.dart';
import '../../../models/repartidor.dart';
import '../../../models/datos_bancarios.dart';
import '../../../apis/helpers/api_exception.dart';
import 'dart:developer' as developer;
import '../pantalla_datos_bancarios.dart';

/// Pantalla de Edición de Perfil del Repartidor
/// Permite editar teléfono, foto, email, nombre y apellido
class PantallaEditarPerfilRepartidor extends StatefulWidget {
  const PantallaEditarPerfilRepartidor({super.key});

  @override
  State<PantallaEditarPerfilRepartidor> createState() =>
      _PantallaEditarPerfilRepartidorState();
}

class _PantallaEditarPerfilRepartidorState
    extends State<PantallaEditarPerfilRepartidor>
    with SingleTickerProviderStateMixin {
  // ============================================
  // SERVICE
  // ============================================
  final RepartidorService _service = RepartidorService();
  final RepartidorDatosBancariosService _datosService = RepartidorDatosBancariosService();

  // ============================================
  // ESTADO
  // ============================================
  PerfilRepartidorModel? _perfil;
  DatosBancarios? _datosBancarios;
  bool _loading = true;
  bool _loadingBancarios = true;
  bool _guardando = false;
  // Esta variable ahora se usará en _guardarCambios para controlar el spinner del avatar
  bool _subiendoFoto = false; 
  String? _error;
  String? _vehiculoSeleccionado;

  // ============================================
  // CONTROLLERS
  // ============================================
  late TextEditingController _telefonoController;

  // Datos del User
  late TextEditingController _emailController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;

  // Foto
  File? _fotoSeleccionada;

  // ============================================
  // ANIMATION
  // ============================================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ============================================
  // COLORES
  // ============================================
  static const Color _naranja = Color(0xFFFF7B00); // corporativo
  static const Color _naranjaOscuro = Color(0xFFE56F00);
  static const Color _verde = Color(0xFF4CAF50);
  static const Color _azul = Color(0xFF0CB7F2); // secundario corporativo
  static const Color _rojo = Color(0xFFF44336);

  // ============================================
  // CICLO DE VIDA
  // ============================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Inicializar controllers vacíos
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();

    _cargarPerfil();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  // ============================================
  // CARGAR PERFIL
  // ============================================

  Future<void> _cargarPerfil() async {
    setState(() {
      _loading = true;
      _loadingBancarios = true;
      _error = null;
    });

    try {
      developer.log('Cargando perfil...', name: 'EditarPerfilRepartidor');

      _perfil = await _service.obtenerMiRepartidor(forzarRecarga: true);

      // Llenar controllers con datos actuales
      _telefonoController.text = _perfil?.telefono ?? '';
      _emailController.text = _perfil?.email ?? '';
      _nombreController.text = _perfil?.firstName ?? '';
      _apellidoController.text = _perfil?.lastName ?? '';
      _vehiculoSeleccionado = _perfil?.vehiculo;

      developer.log('Perfil cargado', name: 'EditarPerfilRepartidor');

      await _cargarDatosBancarios();

      setState(() => _loading = false);
      _animationController.forward();
    } on ApiException catch (e) {
      developer.log('Error API: ${e.message}', name: 'EditarPerfilRepartidor');
      setState(() {
        _error = e.getUserFriendlyMessage();
        _loading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error inesperado',
        name: 'EditarPerfilRepartidor',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = 'Error al cargar perfil';
        _loading = false;
      });
    }
  }

  Future<void> _cargarDatosBancarios() async {
    try {
      final datos = await _datosService.obtenerDatosBancarios();
      if (mounted) {
        setState(() {
          _datosBancarios = datos;
          _loadingBancarios = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error cargando datos bancarios',
        name: 'EditarPerfilRepartidor',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _loadingBancarios = false);
      }
    }
  }

  // ============================================
  // SELECCIONAR FOTO
  // ============================================

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _naranja),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _azul),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_perfil?.fotoPerfil != null || _fotoSeleccionada != null)
              ListTile(
                leading: const Icon(Icons.delete, color: _rojo),
                title: const Text('Eliminar foto'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (opcion == null || !mounted) return;

    if (opcion == 'delete') {
      setState(() => _fotoSeleccionada = null);
      // Marcar para eliminar (se procesará al guardar)
      return;
    }

    final ImageSource source =
        opcion == 'camera' ? ImageSource.camera : ImageSource.gallery;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 5) {
        if (!mounted) return;
        _mostrarError('La imagen es muy grande (máx 5MB)');
        return;
      }

      setState(() => _fotoSeleccionada = imageFile);
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  // ============================================
  // VALIDACIÓN
  // ============================================

  bool _validarFormulario() {
    // Validar teléfono
    final telefono = _telefonoController.text.trim();
    if (telefono.isNotEmpty) {
      if (!telefono.startsWith('09') && !telefono.startsWith('+')) {
        _mostrarError('El teléfono debe comenzar con 09 o +593');
        return false;
      }
      if (telefono.startsWith('09') && telefono.length != 10) {
        _mostrarError('El teléfono debe tener 10 dígitos');
        return false;
      }
    }

    // Validar email
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        _mostrarError('El email no es válido');
        return false;
      }
    }

    // Validar nombre
    final nombre = _nombreController.text.trim();
    if (nombre.isNotEmpty && nombre.length < 2) {
      _mostrarError('El nombre debe tener al menos 2 caracteres');
      return false;
    }

    // Validar apellido
    final apellido = _apellidoController.text.trim();
    if (apellido.isNotEmpty && apellido.length < 2) {
      _mostrarError('El apellido debe tener al menos 2 caracteres');
      return false;
    }

    if ((_vehiculoSeleccionado ?? '').isEmpty) {
      _mostrarError('Selecciona un vehículo');
      return false;
    }

    return true;
  }

  // ============================================
  // GUARDAR CAMBIOS
  // ============================================

  Future<void> _guardarCambios() async {
    if (!_validarFormulario()) return;

    setState(() {
      _guardando = true;
      _error = null;
      // Si hay una foto seleccionada, activamos el flag de "Subiendo Foto"
      if (_fotoSeleccionada != null) {
        _subiendoFoto = true;
      }
    });

    try {
      developer.log('Guardando cambios...', name: 'EditarPerfilRepartidor');

      // Detectar cambios en datos del repartidor
      final telefonoNuevo = _telefonoController.text.trim();

      final vehiculoNuevo = _vehiculoSeleccionado ?? '';
      final hayCambiosPerfil = telefonoNuevo != (_perfil?.telefono ?? '') ||
          vehiculoNuevo != (_perfil?.vehiculo ?? '') ||
          _fotoSeleccionada != null;

      // Detectar cambios en datos del usuario
      final emailNuevo = _emailController.text.trim();
      final nombreNuevo = _nombreController.text.trim();
      final apellidoNuevo = _apellidoController.text.trim();

      final hayCambiosContacto = emailNuevo != (_perfil?.email ?? '') ||
          nombreNuevo != (_perfil?.firstName ?? '') ||
          apellidoNuevo != (_perfil?.lastName ?? '');

      if (!hayCambiosPerfil && !hayCambiosContacto) {
        _mostrarInfo('No hay cambios para guardar');
        // Importante: Resetear estados si salimos temprano
        setState(() {
          _guardando = false;
          _subiendoFoto = false;
        });
        return;
      }

      //  Actualizar datos del repartidor (si hay cambios)
      if (hayCambiosPerfil) {
        developer.log('Actualizando perfil...', name: 'EditarPerfilRepartidor');

        _perfil = await _service.actualizarMiPerfil(
          telefono: telefonoNuevo.isNotEmpty ? telefonoNuevo : null,
          vehiculo: vehiculoNuevo.isNotEmpty ? vehiculoNuevo : null,
          fotoPerfil: _fotoSeleccionada,
        );
      }

      //  Actualizar datos del usuario (si hay cambios)
      if (hayCambiosContacto) {
        developer.log('Actualizando contacto...', name: 'EditarPerfilRepartidor');

        _perfil = await _service.actualizarMiContacto(
          email: emailNuevo.isNotEmpty ? emailNuevo : null,
          firstName: nombreNuevo.isNotEmpty ? nombreNuevo : null,
          lastName: apellidoNuevo.isNotEmpty ? apellidoNuevo : null,
        );
      }

      // Limpiar foto seleccionada
      _fotoSeleccionada = null;

      developer.log('Cambios guardados', name: 'EditarPerfilRepartidor');

      // Reseteamos el estado de subida
      setState(() {
        _guardando = false;
        _subiendoFoto = false;
      });

      if (mounted) {
        _mostrarExito('Perfil actualizado correctamente');

        // Volver a la pantalla anterior después de un delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true); // true = hubo cambios
        }
      }
    } on ApiException catch (e) {
      developer.log('Error API: ${e.message}', name: 'EditarPerfilRepartidor');
      setState(() {
        _error = e.getUserFriendlyMessage();
        _guardando = false;
        _subiendoFoto = false; // Resetear en caso de error
      });
      _mostrarError(_error!);
    } catch (e, stackTrace) {
      developer.log(
        'Error inesperado',
        name: 'EditarPerfilRepartidor',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = 'Error al guardar cambios';
        _guardando = false;
        _subiendoFoto = false; // Resetear en caso de error
      });
      _mostrarError(_error!);
    }
  }

  // ============================================
  // MENSAJES
  // ============================================

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _azul,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _loading ? _buildCargando() : _buildContenido(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Editar Perfil',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_naranja, _naranjaOscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      // Sin botón en AppBar - los botones están abajo
    );
  }

  Widget _buildCargando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         const CircularProgressIndicator(color: _naranja),
          const SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildFotoPerfil(),
            const SizedBox(height: 24),
            _buildSeccionDatosRepartidor(),
            const SizedBox(height: 16),
            _buildSeccionDatosContacto(),
            const SizedBox(height: 16),
            _buildSeccionDatosBancarios(),
            const SizedBox(height: 24),
            _buildBotones(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FOTO DE PERFIL
  // ============================================

  Widget _buildFotoPerfil() {
    // Determinar qué imagen mostrar
    ImageProvider? imageProvider;

    if (_fotoSeleccionada != null) {
      imageProvider = FileImage(_fotoSeleccionada!);
    } else if (_perfil?.fotoPerfil != null) {
      imageProvider = NetworkImage(_perfil!.fotoPerfil!);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_naranja.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: GestureDetector(
        onTap: _subiendoFoto ? null : _seleccionarFoto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _naranja.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 60, color: _naranja)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _naranja,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: _subiendoFoto
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
            if (_fotoSeleccionada != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _verde,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SECCIÓN: DATOS DEL REPARTIDOR
  // ============================================

  Widget _buildSeccionDatosRepartidor() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.badge, color: _naranja),
                 SizedBox(width: 8),
                Text(
                  'Datos del Repartidor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Teléfono
                TextField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  maxLength: 13,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '0987654321',
                    prefixIcon:const Icon(Icons.phone, color: _naranja),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _vehiculoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Vehículo',
                    prefixIcon: const Icon(Icons.directions_bike, color: _naranja),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'motocicleta', child: Text('Motocicleta')),
                    DropdownMenuItem(value: 'bicicleta', child: Text('Bicicleta')),
                    DropdownMenuItem(value: 'automovil', child: Text('Automóvil')),
                    DropdownMenuItem(value: 'camioneta', child: Text('Camioneta')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (val) => setState(() => _vehiculoSeleccionado = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECCIÓN: DATOS DE CONTACTO (USER)
  // ============================================

  Widget _buildSeccionDatosContacto() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const Padding(
            padding:EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.person, color: _azul),
                 SizedBox(width: 8),
                Text(
                  'Datos de Contacto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'correo@ejemplo.com',
                    prefixIcon:const Icon(Icons.email, color: _azul),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre
                TextField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Juan',
                    prefixIcon: const Icon(Icons.person_outline, color: _azul),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Apellido
                TextField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    hintText: 'Pérez',
                    prefixIcon:const Icon(Icons.person_outline, color: _azul),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECCIÓN: DATOS BANCARIOS
  // ============================================

  Widget _buildSeccionDatosBancarios() {
    final tieneDatos = _datosBancarios?.estanCompletos ?? false;
    final numeroCuenta = _mascarNumeroCuenta(_datosBancarios?.bancoNumeroCuenta);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: _azul),
                SizedBox(width: 8),
                Text(
                  'Cuenta bancaria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingBancarios)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Text(
                  tieneDatos
                      ? '${_datosBancarios?.bancoNombre ?? ''} · ${_datosBancarios?.tipoCuentaDisplay ?? _datosBancarios?.bancoTipoCuenta ?? ''}\nCuenta $numeroCuenta'
                      : 'Agrega tus datos bancarios para recibir pagos por transferencia.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _abrirPantallaBancaria,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _azul,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: Text(
                      tieneDatos ? 'Editar cuenta bancaria' : 'Agregar cuenta bancaria',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPantallaBancaria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaDatosBancarios()),
    );
    await _cargarDatosBancarios();
  }

  String _mascarNumeroCuenta(String? numero) {
    if (numero == null || numero.isEmpty) return 'no configurada';
    if (numero.length <= 4) return numero;
    final visibles = numero.substring(numero.length - 4);
    return '****$visibles';
  }

  // ============================================
  // BOTONES
  // ============================================

  Widget _buildBotones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _guardando ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _rojo,
                side: const BorderSide(color: _rojo, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _guardando ? null : _guardarCambios,
              style: FilledButton.styleFrom(
                backgroundColor: _verde,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
