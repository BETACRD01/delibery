// lib/screens/user/perfil/configuracion/direcciones/pantalla_lista_direcciones.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/usuario.dart';
import '../../../../../services/toast_service.dart';
import '../../../../../services/usuarios_service.dart';
import '../../../../../theme/app_colors_primary.dart';
import '../../../../../theme/jp_theme.dart';
import 'pantalla_mis_direcciones.dart';

class PantallaListaDirecciones extends StatefulWidget {
  const PantallaListaDirecciones({super.key});

  @override
  State<PantallaListaDirecciones> createState() =>
      _PantallaListaDireccionesState();
}

class _PantallaListaDireccionesState extends State<PantallaListaDirecciones> {
  final _usuarioService = UsuarioService();
  List<DireccionModel> _direcciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _usuarioService.listarDirecciones(forzarRecarga: true);
      if (mounted) setState(() => _direcciones = data);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar tus direcciones');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _nuevaDireccion() async {
    final resultado = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaAgregarDireccion()),
    );

    // Recargar lista si hubo cambios
    if (resultado == true) {
      await _cargarDirecciones();
    }
  }

  Future<void> _editarDireccion(DireccionModel dir) async {
    final resultado = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) => PantallaAgregarDireccion(direccion: dir),
      ),
    );

    // Recargar lista si hubo cambios
    if (resultado == true) {
      await _cargarDirecciones();
    }
  }

  Future<void> _eliminarDireccion(DireccionModel dir) async {
    try {
      await _usuarioService.eliminarDireccion(dir.id);
      if (mounted) {
        ToastService().showSuccess(
          context,
          'Dirección eliminada correctamente',
        );
        await _cargarDirecciones();
      }
    } catch (e) {
      if (!mounted) return;
      ToastService().showError(context, 'Error al eliminar: $e');
    }
  }

  void _mostrarDialogoEliminar(DireccionModel dir) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.delete,
              color: JPCupertinoColors.systemRed(context),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Eliminar dirección'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar esta dirección?\n\n"${dir.etiqueta.isNotEmpty ? dir.etiqueta : dir.direccion}"',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _eliminarDireccion(dir);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(context),
        middle: const Text('Mis Direcciones'),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Contenido principal
            SafeArea(
              child: _cargando
                  ? Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                        color: JPCupertinoColors.systemGrey(context),
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : _direcciones.isEmpty
                  ? _buildEmpty()
                  : _buildLista(),
            ),

            // Botón flotante iOS-style
            Positioned(
              bottom: 16,
              right: 16,
              child: SafeArea(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: AppColorsPrimary.main,
                  borderRadius: BorderRadius.circular(24),
                  onPressed: _nuevaDireccion,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.location_fill,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Nueva dirección',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: JPCupertinoColors.systemRed(context),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: JPCupertinoColors.label(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _cargarDirecciones,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorsPrimary.main.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.location_slash,
                size: 64,
                color: AppColorsPrimary.main,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes direcciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: JPCupertinoColors.label(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega una dirección de entrega para\nrecibir tus pedidos más rápido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JPCupertinoColors.secondaryLabel(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _nuevaDireccion,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.location_fill,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Agregar primera dirección',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _cargarDirecciones),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDireccionCard(_direcciones[index]),
              ),
              childCount: _direcciones.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDireccionCard(DireccionModel dir) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: GestureDetector(
        onTap: () => _editarDireccion(dir),
        child: Container(
          color: CupertinoColors.transparent,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dir.esPredeterminada
                      ? AppColorsPrimary.main.withValues(alpha: 0.15)
                      : JPCupertinoColors.systemGrey6(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  dir.esPredeterminada
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.location,
                  color: dir.esPredeterminada
                      ? AppColorsPrimary.main
                      : JPCupertinoColors.systemGrey(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tituloDireccion(dir),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: JPCupertinoColors.label(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dir.esPredeterminada)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsPrimary.main.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColorsPrimary.main,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (dir.direccionCompleta.isNotEmpty &&
                        !_esPlaceholder(dir.direccionCompleta)) ...[
                      Text(
                        dir.direccionCompleta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: JPCupertinoColors.secondaryLabel(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (dir.ciudad != null && dir.ciudad!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 14,
                            color: JPCupertinoColors.secondaryLabel(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dir.ciudad!,
                            style: TextStyle(
                              color: JPCupertinoColors.secondaryLabel(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dir.telefonoContacto != null &&
                        dir.telefonoContacto!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.phone,
                            size: 14,
                            color: JPCupertinoColors.secondaryLabel(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dir.telefonoContacto!,
                            style: TextStyle(
                              color: JPCupertinoColors.secondaryLabel(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botón de opciones
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => _mostrarOpciones(dir),
                child: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: JPCupertinoColors.secondaryLabel(context),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpciones(DireccionModel dir) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: JPCupertinoColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JPCupertinoColors.systemGrey4(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _editarDireccion(dir);
                },
                child: Container(
                  color: CupertinoColors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil,
                        color: AppColorsPrimary.main,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Editar dirección',
                        style: TextStyle(
                          fontSize: 16,
                          color: JPCupertinoColors.label(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 0.5,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: JPCupertinoColors.separator(context),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoEliminar(dir);
                },
                child: Container(
                  color: CupertinoColors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.delete,
                        color: JPCupertinoColors.systemRed(context),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Eliminar dirección',
                        style: TextStyle(
                          fontSize: 16,
                          color: JPCupertinoColors.systemRed(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _tituloDireccion(DireccionModel dir) {
    if (dir.etiqueta.isNotEmpty && !_esPlaceholder(dir.etiqueta)) {
      return dir.etiqueta;
    }
    if (dir.direccion.isNotEmpty && !_esPlaceholder(dir.direccion)) {
      return dir.direccion;
    }
    if (dir.direccionCompleta.isNotEmpty &&
        !_esPlaceholder(dir.direccionCompleta)) {
      return dir.direccionCompleta;
    }
    if (dir.ciudad != null && dir.ciudad!.isNotEmpty) {
      return dir.ciudad!;
    }
    return 'Dirección guardada';
  }

  bool _esPlaceholder(String valor) {
    final v = valor.toLowerCase().trim();
    return RegExp(r'^direcci[oó]n\s*\d+$').hasMatch(v);
  }
}
