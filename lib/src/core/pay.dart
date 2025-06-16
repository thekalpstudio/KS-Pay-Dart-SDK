import 'package:ks_pay/ks_pay.dart';
import 'package:ks_pay/src/core/pay_impl.dart';

/// Abstract class defining the payment interface.
abstract class KsPay {
  /// Starts the payment process using the details provided during initialization.
  ///
  /// [signature] is the unique identifier for the payment transaction.
  /// [onSuccess] is called when the payment is successful.
  /// [onError] is called when the payment fails.
  /// [isSandbox] determines whether to use sandbox environment (default: false)
  Future<void> startPayment({
    required String signature,
    required void Function(PaymentResponse) onSuccess,
    required void Function(PaymentError) onError,
    bool isSandbox = false,
  });

  /// Disposes of payment gateway resources.
  ///
  /// Call this method when you're done with the payment process,
  /// typically in the dispose method of your widget.
  void dispose();

  /// Gets the singleton instance of KsPay implementation.
  static KsPay get instance => KsPayImpl.instance;
}
