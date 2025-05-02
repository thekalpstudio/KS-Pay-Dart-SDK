import 'package:ks_pay/ks_pay.dart';
import '../services/payment_service.dart';

/// Implementation of the KsPay abstract class as a singleton.
class KsPayImpl implements KsPay {
  // Singleton instance
  static final KsPayImpl _instance = KsPayImpl._internal();

  // Factory constructor to return the singleton instance
  factory KsPayImpl() => _instance;

  // Private constructor for singleton pattern
  KsPayImpl._internal();

  // Static getter to access the singleton instance
  static KsPay get instance => _instance;

  // Private variables to store payment information
  String? _signature;

  @override
  Future<void> initialize({
    required String signature,
  }) async {
    _signature = signature;
  }

  @override
  Future<void> startPayment({
    required void Function(PaymentResponse) onSuccess,
    required void Function(PaymentError) onError,
  }) async {
    if (_signature == null) {
      throw Exception('KsPay not initialized. Call initialize() first.');
    }

    await PaymentService.processPayment(
      signature: _signature!,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  @override
  void dispose() {
    PaymentService.dispose();
    _signature = null;
  }
}
