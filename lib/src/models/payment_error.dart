/// Represents a payment error.
class PaymentError {
  /// Error code from the payment gateway or internal error code.
  final int code;

  /// Human-readable error message.
  final String message;

  final dynamic rawError;

  /// Creates a new [PaymentError] instance.
  PaymentError({required this.code, required this.message, this.rawError});

  @override
  String toString() => 'PaymentError(code: $code, message: $message)';
}
