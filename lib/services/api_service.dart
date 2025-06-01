import '../model/coin.dart'; // Pastikan path ini benar
import 'base_network.dart'; // Import BaseNetworkService

class ApiService {
  final BaseNetworkService _networkService = BaseNetworkService();

  static const String _cryptoApiUrl =
      'https://be-projek-mobile-713031961242.us-central1.run.app/coins';

  Future<List<Coin>> fetchCoins() async {
    try {
      final responseData = await _networkService.get(_cryptoApiUrl);
      if (responseData is List) {
        return responseData
            .map((json) => Coin.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw NetworkException('Format data tidak valid diterima dari API.');
      }
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Gagal memproses data koin: ${e.toString()}');
    }
  }

}
