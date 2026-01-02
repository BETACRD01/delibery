import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

class DispositivosApi {
  final _client = ApiClient();

  /// Obtener lista de dispositivos (sesiones activas)
  Future<List<dynamic>> listarDispositivos() async {
    final res = await _client.get(ApiConfig.authDispositivos);
    // ApiClient siempre devuelve un Map. Si es lista, la envuelve en 'data'.
    // Si es paginado por Django, viene en 'results'.
    if (res.containsKey('results')) return res['results'] as List<dynamic>;
    if (res.containsKey('data')) return res['data'] as List<dynamic>;
    return [];
  }

  /// Cerrar sesión de un dispositivo específico
  Future<void> cerrarSesionDispositivo(int id) async {
    final url = ApiConfig.authCerrarSesionDispositivo(id);
    await _client.post(url, {});
  }
}
