import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Untuk SocketException

// Custom Exception untuk Network Errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody; // Tambahkan ini untuk info lebih lanjut

  NetworkException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    return 'NetworkException: $message (Status Code: $statusCode)\nResponse: $responseBody';
  }
}

class BaseNetworkService {
  Future<dynamic> get(String url) async {
    final uri = Uri.parse(url);
    print('BaseNetworkService: Mengirim GET request ke $url'); // Logging
    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15)); // Tambahkan timeout
      print(
        'BaseNetworkService: Menerima response dengan status ${response.statusCode}',
      ); // Logging
      return _processResponse(response);
    } on SocketException catch (e) {
      print('BaseNetworkService: SocketException - ${e.toString()}'); // Logging
      throw NetworkException(
        'Tidak ada koneksi internet atau server tidak ditemukan.',
        responseBody: e.toString(),
      );
    }
  }
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null; // atau throw NetworkException('Empty response body');
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw NetworkException(
          'Gagal mem-parsing JSON: ${e.toString()}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } else {
      print(
        'BaseNetworkService: Error dengan status ${response.statusCode}, body: ${response.body}',
      ); // Logging
      throw NetworkException(
        'Error dari server (Status ${response.statusCode})',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }
}
