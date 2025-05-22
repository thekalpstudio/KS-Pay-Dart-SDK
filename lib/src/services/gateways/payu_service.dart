import 'dart:developer';
import 'package:ks_pay/ks_pay.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import '../payment_service.dart';
import 'payu_hash_service.dart';

/// Service for handling PayU payments.
class PayUService implements PaymentGateway, PayUCheckoutProProtocol {
  PayUCheckoutProFlutter? _checkoutPro;
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;
  final PayUHashService _hashService;
  String? _txnId;

  /// Creates an instance of PayUService with optional custom hash service
  PayUService({PayUHashService? hashService})
      : _hashService = hashService ?? PayUHashService();

  /// Initializes the PayU service with callbacks for payment results.
  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
    required String txnId,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _txnId = txnId;
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
      final data = options['details']['initiateTransaction'];

      // Initialize if not already initialized
      if (_checkoutPro == null) {
        initialize(
          onSuccess: onSuccess,
          onError: onError,
          txnId: options['altTxnId'],
        );
      } else {
        _onSuccess = onSuccess;
        _onError = onError;
      }
      log('Processing payment with options: $data');
      // Prepare payment parameters
      final Map<String, dynamic> paymentParams = {
        PayUPaymentParamKey.key: data['key'],
        PayUPaymentParamKey.amount: data['amount'].toString(),
        PayUPaymentParamKey.productInfo: data['productinfo'],
        PayUPaymentParamKey.firstName: data['firstname'],
        PayUPaymentParamKey.email: data['email'],
        PayUPaymentParamKey.phone: data['phone'],
        PayUPaymentParamKey.environment: '1', // 0 for production, 1 for test
        PayUPaymentParamKey.transactionId: options['altTxnId'],
        PayUPaymentParamKey.android_surl: data['surl'],
        PayUPaymentParamKey.android_furl: data['furl'],
        PayUPaymentParamKey.ios_surl: data['surl'],
        PayUPaymentParamKey.ios_furl: data['furl'],
        PayUPaymentParamKey.userCredential: "${data['key']}:${data['email']}",
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
  Future<void> generateHash(Map response) async {
    if (_txnId == null) {
      log('Transaction ID is null. Cannot generate hash.');
      _onError?.call(PaymentError(
        code: -5,
        message: 'Transaction ID is missing for hash generation.',
      ));
      return;
    }

    try {
      final hashResponse = await _hashService.generateHashForTransaction(
        txnId: _txnId!,
        response: response,
      );
      log('Hash generated: $hashResponse');
      _checkoutPro?.hashGenerated(hash: hashResponse);
    } catch (e, stackTrace) {
      log('Error generating hash: $e', stackTrace: stackTrace);
      _onError?.call(PaymentError(
        code: -5,
        message: 'Hash generation failed: $e',
      ));
      dispose();
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
