import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ks_pay/src/utils/api_constants.dart';

/// Configuration for PayU hash generation service
class PayUHashConfig {
  final String apiEndpoint;
  final Map<String, String> defaultHeaders;
  final bool isSandbox;

  const PayUHashConfig({
    String? apiEndpoint,
    this.defaultHeaders = const {'origin': 'kspay-flutter-v1'},
    this.isSandbox = false,
  }) : apiEndpoint = apiEndpoint ??
            '${isSandbox ? ApiConstants.sandboxBaseUrl : ApiConstants.liveBaseUrl}/payU/hash';
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
      final hashName = response['hashName'];

      return {
        hashName: decodedResponse['result'],
      };
    } catch (e) {
      rethrow;
    }
  }
}
