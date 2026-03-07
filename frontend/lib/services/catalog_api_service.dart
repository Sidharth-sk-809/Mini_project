import '../models/product_model.dart';
import 'api_client.dart';

class CatalogApiService {
  CatalogApiService._();

  static Future<bool> syncCatalog({required int rangeKm}) async {
    try {
      final payload = await ApiClient.get(
        '/api/catalog/bootstrap',
        query: {'range_km': rangeKm},
      );
      DummyData.applyRemoteBootstrap(payload);
      return true;
    } catch (_) {
      return false;
    }
  }
}
