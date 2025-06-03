import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

// Custom Exception untuk Network Errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  NetworkException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    return 'NetworkException: $message (Status Code: $statusCode)\nResponse: $responseBody';
  }
}

class BaseNetworkService {
  final http.Client _client;

  BaseNetworkService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    print('BaseNetworkService: Mengirim GET request ke $url'); // Logging

    try {
      final response = await _client
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print(
          'BaseNetworkService: Menerima response dengan status ${response.statusCode}'); // Logging
      return _processResponse(response);
    } on SocketException catch (e) {
      print('BaseNetworkService: SocketException - ${e.toString()}'); // Logging
      throw NetworkException(
        'Tidak ada koneksi internet atau server tidak ditemukan.',
        responseBody: e.toString(),
      );
    } catch (e) {
      throw NetworkException(
        'Network error: ${e.toString()}',
        responseBody: e.toString(),
      );
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      try {
        return json.decode(response.body);
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
      );
      throw NetworkException(
        'Error dari server',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
