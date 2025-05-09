import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Configuration for PayU hash generation service
class PayUHashConfig {
  final String apiEndpoint;
  final Map<String, String> defaultHeaders;

  const PayUHashConfig({
    this.apiEndpoint = 'https://qa-ks-pay-openapi.p2eppl.com/payU/hash',
    this.defaultHeaders = const {'origin': 'kspay-flutter-v1'},
  });
}

/// Service responsible for generating hashes required for PayU transactions
class PayUHashService {
  final PayUHashConfig _config;

  /// Creates a new PayUHashService with optional custom configuration
  PayUHashService({PayUHashConfig? config})
      : _config = config ?? const PayUHashConfig();

  /// Generates a hash for a PayU transaction
  ///
  /// [txnId] is the transaction ID associated with the payment
  /// [response] contains the hash request data from the PayU SDK
  /// Returns a map containing the generated hash with the appropriate key
  Future<Map<String, dynamic>> generateHashForTransaction({
    required String txnId,
    required Map response,
  }) async {
    try {
      log('Generating hash for txnId: $txnId with data: $response');

      final url = Uri.parse('${_config.apiEndpoint}/$txnId');

      final result = await http.post(
        url,
        headers: _config.defaultHeaders,
        body: response,
      );

      if (result.statusCode != 201) {
        throw Exception(
          'Failed to generate hash: ${result.body}',
        );
      }

      final decodedResponse = json.decode(result.body);
      final hashName = response[
          'hashName']; // Using string directly instead of constant to avoid dependency

      return {
        hashName: decodedResponse['result'],
      };
    } catch (e) {
      rethrow;
    }
  }
}
