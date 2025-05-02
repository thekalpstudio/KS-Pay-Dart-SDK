import 'package:ks_pay/ks_pay.dart';
import 'package:ks_pay/src/core/pay_impl.dart';

/// Abstract class defining the payment interface.
abstract class KsPay {
  /// Initializes the payment service with the signature.
  ///
  /// [signature] is a unique identifier for the order.
  Future<void> initialize({
    required String signature,
  });

  /// Starts the payment process using the details provided during initialization.
  ///
  /// [onSuccess] is called when the payment is successful.
  /// [onError] is called when the payment fails.
  Future<void> startPayment({
    required void Function(PaymentResponse) onSuccess,
    required void Function(PaymentError) onError,
  });

  /// Disposes of payment gateway resources.
  ///
  /// Call this method when you're done with the payment process,
  /// typically in the dispose method of your widget.
  void dispose();

  /// Gets the singleton instance of KsPay implementation.
  static KsPay get instance => KsPayImpl.instance;
}
