import 'dart:developer' as developer;
import 'package:ks_pay/ks_pay.dart';
import 'package:ks_pay/src/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Service for handling Razorpay payments.
class RazorpayService {
  final Razorpay _razorpay;
  PaymentSuccessCallback? _onPaymentSuccessUserCallback;
  PaymentErrorCallback? _onPaymentErrorUserCallback;
  // You can add a specific callback for external wallets if needed:
  // Function(ExternalWalletResponse response)? _onExternalWalletUserCallback;

  // Constants for Razorpay event names
  static const String _eventPaymentSuccess = Razorpay.EVENT_PAYMENT_SUCCESS;
  static const String _eventPaymentError = Razorpay.EVENT_PAYMENT_ERROR;
  static const String _eventExternalWallet = Razorpay.EVENT_EXTERNAL_WALLET;

  /// Creates an instance of RazorpayService and initializes Razorpay event listeners.
  RazorpayService() : _razorpay = Razorpay() {
    _attachRazorpayListeners();
  }

  void _attachRazorpayListeners() {
    _razorpay.on(_eventPaymentSuccess, _handlePaymentSuccess);
    _razorpay.on(_eventPaymentError, _handlePaymentError);
    _razorpay.on(_eventExternalWallet, _handleExternalWallet);
  }

  /// Configures the callback functions for payment success and failure events.
  /// This method should be called before [startPayment].
  void configureHandlers({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
    // Function(ExternalWalletResponse response)? onExternalWallet, // Optional
  }) {
    _onPaymentSuccessUserCallback = onSuccess;
    _onPaymentErrorUserCallback = onError;
    // _onExternalWalletUserCallback = onExternalWallet;
  }

  /// Internal handler for successful payment events from Razorpay.
  void _handlePaymentSuccess(PaymentSuccessResponse result) {
    developer.log(
        'Razorpay Payment Success: PaymentID: ${result.paymentId}, OrderID: ${result.orderId}');
    final paymentId = result.paymentId;
    if (paymentId == null) {
      // This is unlikely for a success event from Razorpay but good to handle.
      _onPaymentErrorUserCallback?.call(
        PaymentError(
          code:
              RazorpayErrorCodes.networkErrorCode, // Or a custom internal code
          message: 'Payment success event received without a payment ID.',
          // Consider adding rawError: {'originalResult': result.toString()} if PaymentError supports it
        ),
      );
      return;
    }

    _onPaymentSuccessUserCallback?.call(
      PaymentResponse(
        paymentId: paymentId,
        rawResponse: {
          'paymentId': paymentId,
          'orderId': result.orderId,
          'signature': result.signature,
        },
      ),
    );
  }

  /// Internal handler for payment failure events from Razorpay.
  void _handlePaymentError(PaymentFailureResponse failure) {
    developer.log(
        'Razorpay Payment Failure: Code: ${failure.code}, Message: ${failure.message}');
    _onPaymentErrorUserCallback?.call(
      PaymentError(
        code: failure.code ?? RazorpayErrorCodes.paymentCancelledErrorCode,
        message: failure.message ?? 'Unknown payment error occurred.',
      ),
    );
  }

  /// Internal handler for external wallet events from Razorpay.
  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log('Razorpay External Wallet: ${response.walletName}');
    // If you have an _onExternalWalletUserCallback:
    // _onExternalWalletUserCallback?.call(response);
    // For now, this event is logged. Implement further handling if needed.
  }

  /// Opens the Razorpay checkout UI with the provided [options].
  ///
  /// Ensure [configureHandlers] has been called with appropriate handlers before this.
  /// Throws a [StateError] if handlers are not configured.
  void startPayment(Map<String, dynamic> options) {
    if (_onPaymentSuccessUserCallback == null ||
        _onPaymentErrorUserCallback == null) {
      throw StateError(
          'Razorpay handlers not configured. Call configureHandlers() before startPayment().');
    }
    developer.log('Starting Razorpay payment with options: $options');
    _razorpay.open(options);
  }

  /// Clears Razorpay resources and event listeners.
  /// This should be called when the service is no longer needed, e.g., in a widget's dispose method.
  void dispose() {
    developer.log('Disposing RazorpayService.');
    _razorpay.clear();
    _onPaymentSuccessUserCallback = null;
    _onPaymentErrorUserCallback = null;
    // _onExternalWalletUserCallback = null;
  }
}

class RazorpayErrorCodes {
  static const int networkErrorCode = 2;
  static const int paymentCancelledErrorCode = 0;
}
