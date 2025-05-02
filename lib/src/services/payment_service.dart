import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ks_pay/ks_pay.dart';

import 'gateways/razorpay_service.dart';
import 'gateways/payu_service.dart';

/// Callback invoked on payment success.
typedef PaymentSuccessCallback = void Function(PaymentResponse response);

/// Callback invoked on payment failure.
typedef PaymentErrorCallback = void Function(PaymentError error);

/// Main service to handle payments.
class PaymentService {
  /// Processes the payment by fetching details from backend and invoking appropriate SDK.
  static Future<void> processPayment({
    required String signature,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) async {
    try {
      final url =
          Uri.parse('https://qa-ks-pay-openapi.p2eppl.com/transaction/process');
      // 1: Fetch payment details from backend
      final response = await http.post(
        url,
        headers: {'x-signature': signature, 'origin': 'kspay-flutter-v1'},
      );

      if (response.statusCode != 201) {
        onError(PaymentError(
          code: response.statusCode,
          message: 'Backend error: ${response.body}',
        ));
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final paymentType = data['result']['gateway'] as String;
      final paymentOptions = data['result']['details'] as Map<String, dynamic>;

      // 2: Route to appropriate SDK
      switch (paymentType.toLowerCase()) {
        case 'razorpay':
          await _processRazorpayPayment(paymentOptions, onSuccess, onError);
          break;
        case 'payu':
          await _processPayUPayment(paymentOptions, onSuccess, onError);
          break;
        default:
          onError(PaymentError(
            code: -1,
            message: 'Unsupported payment type: $paymentType',
          ));
      }
    } catch (e) {
      onError(PaymentError(code: -2, message: e.toString()));
    }
  }

  /// Processes a payment through Razorpay.
  static Future<void> _processRazorpayPayment(
    Map<String, dynamic> options,
    PaymentSuccessCallback onSuccess,
    PaymentErrorCallback onError,
  ) async {
    RazorpayService.initialize(
      onSuccess: onSuccess,
      onError: onError,
    );
    RazorpayService.startPayment(options);
  }

  /// Processes a payment through PayU.
  static Future<void> _processPayUPayment(
    Map<String, dynamic> options,
    PaymentSuccessCallback onSuccess,
    PaymentErrorCallback onError,
  ) async {
    await PayUService.processPayment(
      options: options['initiateTransaction'] as Map<String, dynamic>,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Disposes of payment gateway resources.
  static void dispose() {
    RazorpayService.dispose();
  }
}
