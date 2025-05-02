import 'package:flutter_test/flutter_test.dart';
import 'package:ks_pay/ks_pay.dart';

void main() {
  group('PaymentResponse', () {
    test('should create a valid PaymentResponse object', () {
      final response = PaymentResponse(
        paymentId: 'pay_123456',
        rawResponse: {'status': 'success', 'amount': 1000},
      );

      expect(response.paymentId, 'pay_123456');
      expect(response.rawResponse['status'], 'success');
      expect(response.rawResponse['amount'], 1000);
    });

    test('toString should return a formatted string', () {
      final response = PaymentResponse(
        paymentId: 'pay_123456',
        rawResponse: {'status': 'success'},
      );

      expect(response.toString(), contains('pay_123456'));
      expect(response.toString(), contains('status'));
      expect(response.toString(), contains('success'));
    });
  });

  group('PaymentError', () {
    test('should create a valid PaymentError object', () {
      final error = PaymentError(
        code: 400,
        message: 'Bad Request',
      );

      expect(error.code, 400);
      expect(error.message, 'Bad Request');
    });

    test('toString should return a formatted string', () {
      final error = PaymentError(
        code: 500,
        message: 'Server Error',
      );

      expect(error.toString(), contains('500'));
      expect(error.toString(), contains('Server Error'));
    });
  });
}
