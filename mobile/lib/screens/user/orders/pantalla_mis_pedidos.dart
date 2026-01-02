import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../models/orders/pedido_model.dart';
import '../../../providers/orders/proveedor_pedido.dart';
import '../../../widgets/cards/jp_order_card.dart';
import '../../../widgets/common/jp_empty_state.dart';
import '../../../widgets/common/jp_cupertino_button.dart';
import '../../../../../theme/app_colors_primary.dart';
import '../../../theme/jp_theme.dart';
import 'pedido_detalle_screen.dart';
import '../../../widgets/cards/jp_courier_card.dart';
import 'pantalla_detalle_courier.dart';

class PantallaMisPedidos extends StatefulWidget {
  const PantallaMisPedidos({super.key});

  @override
  State<PantallaMisPedidos> createState() => _PantallaMisPedidosState();
}

class _PantallaMisPedidosState extends State<PantallaMisPedidos>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  DateTime _ultimaRecarga = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPedidos(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _cargarPedidos({bool refresh = false}) {
    _ultimaRecarga = DateTime.now();
    context.read<PedidoProvider>().cargarPedidos(refresh: refresh);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final provider = context.read<PedidoProvider>();
      final yaCargando = provider.isLoading;
      final listaVacia = provider.pedidos.isEmpty;
      final haceMucho =
          DateTime.now().difference(_ultimaRecarga) >
          const Duration(seconds: 30);

      if (!yaCargando && (listaVacia || haceMucho)) {
        _cargarPedidos(refresh: true);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Cargar más cuando falten 200px para llegar al final
    if (maxScroll - currentScroll <= 200) {
      context.read<PedidoProvider>().cargarPedidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(context),
        border: null,
        middle: Text(
          'Mis Pedidos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: JPCupertinoColors.label(context),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _cargarPedidos(refresh: true),
          child: Icon(
            CupertinoIcons.refresh,
            size: 22,
            color: AppColorsPrimary.main,
          ),
        ),
      ),
      child: Consumer<PedidoProvider>(
        builder: (context, provider, child) {
          if (provider.error != null && provider.pedidos.isEmpty) {
            return _buildError(provider.error!, context);
          }

          if (provider.pedidos.isEmpty && provider.isLoading) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          if (provider.pedidos.isEmpty) {
            return _buildSinPedidos(context);
          }

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async => _cargarPedidos(refresh: true),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == provider.pedidos.length) {
                        return provider.hasMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final pedido = provider.pedidos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTarjetaPedido(pedido),
                      );
                    },
                    childCount:
                        provider.pedidos.length + (provider.hasMore ? 1 : 0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTarjetaPedido(PedidoListItem pedido) {
    // Si es un encargo (Courier), usamos la tarjeta específica
    if (pedido.tipo.toLowerCase() == 'directo' ||
        pedido.tipo.toLowerCase() == 'courier') {
      return JPCourierCard(
        numeroPedido: pedido.numeroPedido,
        estado: pedido.estado,
        estadoDisplay: pedido.estadoDisplay,
        direccionOrigen:
            pedido.proveedorNombre ??
            'Origen desconocido', // En courier, proveedorNombre suele mapearse al origen o nombre del remitente si no hay proveedor real
        direccionDestino: pedido.direccionEntrega,
        creadoEn: pedido.creadoEn,
        total: pedido.totalConRecargo,
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => PantallaDetalleCourier(pedidoId: pedido.id),
          ),
        ),
        actionButton: _buildBotonAccion(pedido, isCourier: true),
      );
    }

    // Pedido normal (Shopping/Comida)
    return JPOrderCard(
      numeroPedido: pedido.numeroPedido,
      estado: pedido.estado,
      estadoDisplay: pedido.estadoDisplay,
      proveedorNombre: pedido.proveedorNombre,
      creadoEn: pedido.creadoEn,
      cantidadItems: pedido.cantidadItems,
      total: pedido.totalConRecargo,
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => PedidoDetalleScreen(pedidoId: pedido.id),
        ),
      ),
      actionButton: _buildBotonAccion(pedido),
    );
  }

  Widget _buildBotonAccion(PedidoListItem pedido, {bool isCourier = false}) {
    if (pedido.estado == 'en_ruta') {
      return JPCupertinoButton.filled(
        text: 'Rastrear',
        icon: CupertinoIcons.map,
        size: JPButtonSize.compact,
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => isCourier
                ? PantallaDetalleCourier(pedidoId: pedido.id)
                : PedidoDetalleScreen(pedidoId: pedido.id),
          ),
        ),
      );
    }
    return JPCupertinoButton.text(
      text: 'Ver Detalles',
      size: JPButtonSize.compact,
      onPressed: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => isCourier
              ? PantallaDetalleCourier(pedidoId: pedido.id)
              : PedidoDetalleScreen(pedidoId: pedido.id),
        ),
      ),
    );
  }

  Widget _buildError(String error, BuildContext context) {
    return JPEmptyState(
      icon: CupertinoIcons.wifi_slash,
      iconColor: JPCupertinoColors.systemRed(context),
      title: 'Algo salió mal',
      message: error,
      actionText: 'Intentar de nuevo',
      onAction: () {
        context.read<PedidoProvider>().limpiarError();
        _cargarPedidos(refresh: true);
      },
    );
  }

  Widget _buildSinPedidos(BuildContext context) {
    return JPEmptyState(
      icon: CupertinoIcons.bag,
      iconColor: JPCupertinoColors.systemGrey(context),
      title: 'No hay pedidos',
      message: 'Desliza hacia abajo o toca actualizar para recargar',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }
}
