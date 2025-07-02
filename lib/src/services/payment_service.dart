import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ks_pay/ks_pay.dart';
import 'package:ks_pay/src/utils/api_constants.dart';

import 'gateways/razorpay_service.dart';
import 'gateways/payu_service.dart';

/// Callback invoked on payment success.
typedef PaymentSuccessCallback = void Function(PaymentResponse response);

/// Callback invoked on payment failure.
typedef PaymentErrorCallback = void Function(PaymentError error);

/// Interface for payment gateway services
abstract class PaymentGateway {
  Future<void> processPayment({
    required Map<String, dynamic> options,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  });

  void dispose();
}

/// Configuration for payment service
class PaymentServiceConfig {
  final String apiEndpoint;
  final Map<String, String> defaultHeaders;
  final bool isSandbox;

  const PaymentServiceConfig({
    String? apiEndpoint,
    this.defaultHeaders = const {'origin': 'kspay-flutter-v1'},
    this.isSandbox = false,
  }) : apiEndpoint = apiEndpoint ??
            '${isSandbox ? ApiConstants.sandboxBaseUrl : ApiConstants.liveBaseUrl}/transaction/process';
}

/// Main service to handle payments.
class PaymentService {
  final http.Client _httpClient;
  final RazorpayService _razorpayService;
  final PayUService _payuService;
  final PaymentServiceConfig _config;

  /// Creates a new payment service instance with dependencies
  PaymentService({
    http.Client? httpClient,
    RazorpayService? razorpayService,
    PayUService? payuService,
    PaymentServiceConfig? config,
  })  : _httpClient = httpClient ?? http.Client(),
        _razorpayService = razorpayService ?? RazorpayService(),
        _config = config ?? const PaymentServiceConfig(),
        _payuService =
            payuService ?? PayUService(isSandbox: config?.isSandbox ?? false);

  /// Processes the payment by fetching details from backend and invoking appropriate SDK.
  Future<void> processPayment({
    required String signature,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) async {
    try {
      final paymentData = await _fetchPaymentDetails(signature);
      await _routeToPaymentGateway(paymentData, onSuccess, onError);
    } catch (e) {
      onError(PaymentError(code: -2, message: e.toString()));
    }
  }

  /// Fetches payment details from the backend
  Future<Map<String, dynamic>> _fetchPaymentDetails(String signature) async {
    final url = Uri.parse(_config.apiEndpoint);
    final headers = {
      'x-signature': signature,
      ..._config.defaultHeaders,
    };

    final response = await _httpClient.post(url, headers: headers);

    if (response.statusCode != 201) {
      throw PaymentError(
        code: response.statusCode,
        message: 'Backend error: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Routes the payment to the appropriate gateway
  Future<void> _routeToPaymentGateway(
    Map<String, dynamic> data,
    PaymentSuccessCallback onSuccess,
    PaymentErrorCallback onError,
  ) async {
    final paymentType = data['result']['gateway'] as String;

    switch (paymentType.toLowerCase()) {
      case 'razorpay':
        await _processRazorpayPayment(data['result'], onSuccess, onError);
        break;
      case 'payu':
        final paymentOptions = data['result'] as Map<String, dynamic>;
        await _processPayUPayment(paymentOptions, onSuccess, onError);
        break;
      default:
        onError(PaymentError(
          code: -1,
          message: 'Unsupported payment type: $paymentType',
        ));
    }
  }

  /// Processes a payment through Razorpay.
  Future<void> _processRazorpayPayment(
    Map<String, dynamic> paymentOptions,
    PaymentSuccessCallback onSuccess,
    PaymentErrorCallback onError,
  ) async {
    final options = {
      'key': paymentOptions['clientId'],
      'amount': paymentOptions['amount'],
      'order_id': paymentOptions['providerOrderId'],
      'config': paymentOptions['config'] ?? {},
    };

    _razorpayService.configureHandlers(
      onSuccess: onSuccess,
      onError: onError,
    );
    _razorpayService.startPayment(options);
  }

  /// Processes a payment through PayU.
  Future<void> _processPayUPayment(
    Map<String, dynamic> data,
    PaymentSuccessCallback onSuccess,
    PaymentErrorCallback onError,
  ) async {
    await _payuService.processPayment(
      options: data,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Disposes of payment gateway resources.
  void dispose() {
    _razorpayService.dispose();
    _payuService.dispose();
    _httpClient.close();
  }
}
