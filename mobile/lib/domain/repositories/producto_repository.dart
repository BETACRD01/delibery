import '../../models/products/producto_model.dart';
import '../../models/core/paginated_response.dart';

abstract class ProductoRepository {
  Future<PaginatedResponse<ProductoModel>> getProductos({
    int page = 1,
    int limit = 20,
    String? busqueda,
    String? categoriaId,
  });
}
