import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/payment_response.dart';
import '../../models/payment_error.dart';
import '../payment_service.dart';

/// Service for handling Razorpay payments.
class RazorpayService implements PaymentGateway {
  Razorpay? _razorpay;

  /// Initializes Razorpay and sets up event listeners.
  void initialize({
    required Function(PaymentResponse) onSuccess,
    required Function(PaymentError) onError,
  }) {
    _razorpay ??= Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse result) {
      onSuccess(
        PaymentResponse(
          paymentId: result.paymentId!,
          rawResponse: {
            'paymentId': result.paymentId,
            'orderId': result.orderId,
            'signature': result.signature,
          },
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse error) {
      onError(
        PaymentError(
          code: error.code!,
          message: error.message!,
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (externalWallet) {
      // handle external wallets if needed
    });
  }

  /// Opens the Razorpay checkout UI with the provided options.
  void startPayment(Map<String, dynamic> options) {
    if (_razorpay == null) {
      throw Exception('Razorpay not initialized. Call initialize() first.');
    }
    _razorpay!.open(options);
  }

  @override
  Future<void> processPayment({
    required Map<String, dynamic> options,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) async {
    initialize(onSuccess: onSuccess, onError: onError);
    startPayment(options);
  }

  /// Disposes of the Razorpay instance.
  @override
  void dispose() {
    if (_razorpay != null) {
      _razorpay!.clear();
      _razorpay = null;
    }
  }
}
