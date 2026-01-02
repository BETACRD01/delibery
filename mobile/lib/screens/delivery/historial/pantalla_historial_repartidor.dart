// lib/screens/delivery/historial/pantalla_historial_repartidor.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile/models/orders/entrega_historial.dart';
import 'package:mobile/services/repartidor/repartidor_service.dart';
import 'package:mobile/screens/delivery/historial/pantalla_detalle_entrega.dart';

/// Pantalla dedicada al historial de entregas vinculada al backend.
class PantallaHistorialRepartidor extends StatefulWidget {
  const PantallaHistorialRepartidor({super.key});

  @override
  State<PantallaHistorialRepartidor> createState() =>
      _PantallaHistorialRepartidorState();
}

class _PantallaHistorialRepartidorState
    extends State<PantallaHistorialRepartidor> {
  static const Color _accent = Color(0xFF0CB7F2); // Celeste corporativo
  static const Color _success = Color(0xFF34C759);
  static const Color _errorColor = Color(0xFFFF3B30);

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _cardBorder => CupertinoColors.separator.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);
  Color get _textSecondary =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  final RepartidorService _service = RepartidorService();
  final ScrollController _scrollController = ScrollController();

  List<EntregaHistorial> _entregas = [];
  double _totalComisiones = 0;
  int _totalEntregas = 0;
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service.obtenerHistorialEntregas();
      final parsed = HistorialEntregasResponse.fromJson(response);
      if (!mounted) return;
      setState(() {
        _entregas = parsed.entregas;
        _totalComisiones = parsed.totalComisiones;
        _totalEntregas = parsed.totalEntregas;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<EntregaHistorial> get _entregasFiltradas {
    if (_busqueda.trim().isEmpty) return _entregas;
    final termino = _busqueda.toLowerCase();
    return _entregas.where((entrega) {
      final nombre = entrega.clienteNombre.toLowerCase();
      final direccion = entrega.clienteDireccion.toLowerCase();
      return nombre.contains(termino) || direccion.contains(termino);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Definir altura segura para el buscador flexible
    // Un valor base más seguro para evitar superposiciones

    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Historial'),
              backgroundColor: _surface,
              border: null,
            ),
            CupertinoSliverRefreshControl(onRefresh: _cargarHistorial),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildResumen(),
                    const SizedBox(height: 16),
                    CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Buscar por cliente o dirección',
                      onChanged: (valor) => setState(() => _busqueda = valor),
                      backgroundColor: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ),
            _buildListadoSliver(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumenItem(
            'Entregas',
            '$_totalEntregas',
            CupertinoIcons.check_mark_circled_solid,
            _accent,
          ),
          _buildResumenItem(
            'Ganancia',
            '\$${_totalComisiones.toStringAsFixed(2)}',
            CupertinoIcons.money_dollar_circle_fill,
            _success,
          ),
          _buildResumenItem(
            'Visibles',
            '${_entregasFiltradas.length}',
            CupertinoIcons.eye_fill,
            CupertinoColors.systemGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
      ],
    );
  }

  Widget _buildListadoSliver() {
    if (_loading && _entregas.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 64,
                  color: _errorColor,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textPrimary),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  color: _accent,
                  borderRadius: BorderRadius.circular(20),
                  onPressed: _cargarHistorial,
                  minimumSize: const Size.square(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listado = _entregasFiltradas;

    if (listado.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'No se encontraron entregas que coincidan con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final entrega = listado[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEntregaCard(entrega),
          );
        }, childCount: listado.length),
      ),
    );
  }

  Widget _buildEntregaCard(EntregaHistorial entrega) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => PantallaDetalleEntrega(entrega: entrega),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(entrega),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 0.5, color: _cardBorder),
              const SizedBox(height: 12),
              _buildLineaDetalle(
                CupertinoIcons.person_fill,
                'Cliente',
                entrega.clienteNombre.isEmpty
                    ? 'Cliente invitado'
                    : entrega.clienteNombre,
              ),
              const SizedBox(height: 8),
              _buildLineaDetalle(
                CupertinoIcons.location_solid,
                'Dirección',
                entrega.clienteDireccion,
              ),
              const SizedBox(height: 8),
              _buildLineaDetalle(
                CupertinoIcons.creditcard_fill,
                'Método',
                entrega.metodoPago,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      entrega.tieneComprobante
                          ? CupertinoIcons.doc_text_fill
                          : CupertinoIcons.doc_text,
                      color: entrega.tieneComprobante
                          ? _success
                          : CupertinoColors.systemGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entrega.tieneComprobante
                          ? 'Comprobante OK'
                          : 'Sin comprobante',
                      style: TextStyle(
                        color: entrega.tieneComprobante
                            ? _success
                            : CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Ganancia: \$${entrega.comisionRepartidor.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                            Text(
                              '\$${entrega.montoTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(EntregaHistorial entrega) {
    final fecha = entrega.fechaFormateada;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#${entrega.id}',
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            fecha,
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ),
        _buildEstadoChip(entrega),
      ],
    );
  }

  Widget _buildLineaDetalle(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: CupertinoColors.systemGrey),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: _textPrimary),
              children: [
                TextSpan(
                  text: '$etiqueta: ',
                  style: TextStyle(color: _textSecondary),
                ),
                TextSpan(text: valor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(EntregaHistorial entrega) {
    final color = entrega.montoTotal > 0 ? _success : _errorColor;
    final text = entrega.tieneComprobante ? 'Completado' : 'Pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
