/// Represents a successful payment response.
class PaymentResponse {
  /// Unique identifier for the payment transaction.
  final String paymentId;

  /// Raw response data from the payment gateway.
  final Map<String, dynamic> rawResponse;

  /// Creates a new [PaymentResponse] instance.
  PaymentResponse({required this.paymentId, required this.rawResponse});

  @override
  String toString() =>
      'PaymentResponse(paymentId: $paymentId, rawResponse: $rawResponse)';
}
