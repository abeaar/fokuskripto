import '../model/coin.dart'; // Pastikan path ini benar
import 'base_network.dart'; // Import BaseNetworkService

class ApiService {
  final BaseNetworkService _networkService = BaseNetworkService();

  // URL dasar API Anda (jika semua endpoint kripto berasal dari sini)
  static const String _cryptoApiUrl =
      'https://be-projek-mobile-713031961242.us-central1.run.app/coins';

  Future<List<Coin>> fetchCoins() async {
    try {
      // Panggil metode get dari BaseNetworkService
      final responseData = await _networkService.get(_cryptoApiUrl);

      // responseData sudah merupakan JSON yang di-decode (List<dynamic> dalam kasus ini)
      if (responseData is List) {
        return responseData
            .map((json) => Coin.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Ini terjadi jika API tidak mengembalikan list seperti yang diharapkan
        throw NetworkException('Format data tidak valid diterima dari API.');
      }
    } on NetworkException {
      // Jika ingin meneruskan NetworkException dari BaseNetworkService apa adanya
      rethrow;
    } catch (e) {
      // Menangkap error lain yang mungkin terjadi saat parsing data
      throw NetworkException('Gagal memproses data koin: ${e.toString()}');
    }
  }

}
