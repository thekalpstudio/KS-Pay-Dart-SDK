import 'dart:developer';
import 'package:ks_pay/ks_pay.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import '../payment_service.dart';

/// Service for handling PayU payments.
class PayUService implements PaymentGateway, PayUCheckoutProProtocol {
  PayUCheckoutProFlutter? _checkoutPro;
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;
  String? _hash;

  /// Creates an instance of PayUService
  PayUService();

  /// Initializes the PayU service with callbacks for payment results.
  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
    required String hash,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _hash = hash;
    _checkoutPro = PayUCheckoutProFlutter(this);
  }

  /// Processes a payment through PayU with the provided options.
  @override
  Future<void> processPayment({
    required Map<String, dynamic> options,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) async {
    try {
      // Initialize if not already initialized
      if (_checkoutPro == null) {
        initialize(
          onSuccess: onSuccess,
          onError: onError,
          hash: options['hash'] as String? ?? '',
        );
      } else {
        _onSuccess = onSuccess;
        _onError = onError;
      }

      // Prepare payment parameters
      final Map<String, dynamic> paymentParams = {
        PayUPaymentParamKey.key: options['key'] ?? '',
        PayUPaymentParamKey.amount: options['amount'] ?? '0',
        PayUPaymentParamKey.productInfo: options['productinfo'] ?? 'kspay',
        PayUPaymentParamKey.firstName: options['firstname'] ?? 'Customer',
        PayUPaymentParamKey.email: options['email'] ?? 'customer@example.com',
        PayUPaymentParamKey.phone: options['phone'] ?? '9999999999',
        PayUPaymentParamKey.environment: '1', // 0 for production, 1 for test
        PayUPaymentParamKey.transactionId:
            options['txnid'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
        PayUPaymentParamKey.android_surl: options['surl'] ??
            'https://www.payumoney.com/mobileapp/payumoney/success.php',
        PayUPaymentParamKey.android_furl: options['furl'] ??
            'https://www.payumoney.com/mobileapp/payumoney/failure.php',
        PayUPaymentParamKey.ios_surl: options['surl'] ??
            'https://www.payumoney.com/mobileapp/payumoney/success.php',
        PayUPaymentParamKey.ios_furl: options['furl'] ??
            'https://www.payumoney.com/mobileapp/payumoney/failure.php',
      };

      // Prepare checkout configuration
      final Map<String, dynamic> checkoutConfig = {
        PayUCheckoutProConfigKeys.merchantName: "kspay",
        PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: true,
      };

      // Open checkout screen
      _checkoutPro!.openCheckoutScreen(
        payUPaymentParams: paymentParams,
        payUCheckoutProConfig: checkoutConfig,
      );
    } catch (e) {
      onError(PaymentError(code: -4, message: e.toString()));
    }
  }

  /// Generates hash for PayU payment verification.
  @override
  generateHash(Map response) async {
    try {
      if (_hash != null) {
        var hashName = response[PayUHashConstantsKeys.hashName];
        final Map<String, String> hashResponse = {hashName: _hash!};
        _checkoutPro!.hashGenerated(hash: hashResponse);
      }
    } catch (e) {
      log('Error generating hash: $e');
      if (_onError != null) {
        _onError!(
            PaymentError(code: -5, message: 'Hash generation failed: $e'));
      }
    }
  }

  /// Handles successful payment response.
  @override
  onPaymentSuccess(dynamic response) {
    log('Payment success: $response');
    if (_onSuccess != null) {
      final Map<String, dynamic> responseMap =
          Map<String, dynamic>.from(response);
      _onSuccess!(
        PaymentResponse(
          paymentId: responseMap['paymentId'] ?? responseMap['txnid'] ?? '',
          rawResponse: responseMap,
        ),
      );
    }
  }

  /// Handles payment failure.
  @override
  onPaymentFailure(dynamic response) {
    log('Payment failure: $response');
    if (_onError != null) {
      final Map<String, dynamic> responseMap =
          Map<String, dynamic>.from(response);
      _onError!(
        PaymentError(
          code: -1,
          message: responseMap['error'] ?? 'Payment failed',
        ),
      );
    }
  }

  /// Handles payment cancellation.
  @override
  onPaymentCancel(dynamic response) {
    log('Payment cancelled: $response');
    if (_onError != null) {
      _onError!(
        PaymentError(
          code: -2,
          message: 'Payment cancelled by user',
        ),
      );
    }
  }

  /// Handles payment errors.
  @override
  onError(dynamic response) {
    log('Payment error: $response');
    if (_onError != null) {
      final Map<String, dynamic> responseMap =
          Map<String, dynamic>.from(response);
      _onError!(
        PaymentError(
          code: responseMap['errorCode'] ?? -3,
          message: responseMap['errorMsg'] ?? 'Payment processing error',
        ),
      );
    }
  }

  @override
  void dispose() {
    _checkoutPro = null;
    _onSuccess = null;
    _onError = null;
  }
}
