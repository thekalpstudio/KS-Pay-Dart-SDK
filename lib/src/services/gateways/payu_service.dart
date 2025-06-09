import 'dart:developer';
import 'package:ks_pay/ks_pay.dart'; // Assuming this defines PaymentGateway, PaymentSuccessCallback, PaymentErrorCallback, PaymentResponse, PaymentError
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import '../payment_service.dart'; // Assuming this is correctly located
import 'payu_hash_service.dart';

/// Service for handling PayU payments.
class PayUService implements PaymentGateway, PayUCheckoutProProtocol {
  PayUCheckoutProFlutter? _checkoutPro;
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;
  final PayUHashService _hashService;
  String? _currentTxnId; // Renamed for clarity

  // Constants for PayU
  static const String _environmentTest = '1';
  static const String _environmentProduction = '0';
  static const String _merchantName = "kspay";
  static const String _netbankingMethod = 'NB';
  static const String _walletMethod = 'WALLET';
  static const String _debitCardMethod = 'CARD';
  static const String _upiMethod = 'UPI';

  /// Creates an instance of PayUService.
  ///
  /// An optional [hashService] can be provided for custom hash generation.
  /// [isSandbox] determines whether to use sandbox environment.
  PayUService({
    PayUHashService? hashService,
    bool isSandbox = false,
  }) : _hashService = hashService ??
            PayUHashService(
              config: PayUHashConfig(isSandbox: isSandbox),
            );

  /// Initializes the PayU service and sets up callbacks for payment results.
  ///
  /// This method should be called before processing any payment.
  /// It configures the success and error handlers for the payment lifecycle.
  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    // Initialize _checkoutPro here if it's always needed after initialization.
    // If it's only needed per transaction, then processPayment is the right place.
    _checkoutPro ??= PayUCheckoutProFlutter(this);
  }

  /// Processes a payment through PayU with the provided [options].
  ///
  /// The [onSuccess] and [onError] callbacks provided here will override
  /// any callbacks set during [initialize] for this specific transaction.
  @override
  Future<void> processPayment({
    required Map<String, dynamic> options,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) async {
    // Update callbacks for this specific transaction
    _onSuccess = onSuccess;
    _onError = onError;

    try {
      // Validate and extract necessary data from options
      final mode = options['mode'] as String?;
      final transactionDetails = options['details']?['initiateTransaction'];
      final String? altTxnId = options['altTxnId'] as String?;

      if (transactionDetails == null || altTxnId == null) {
        _handleError(PaymentError(
          code: PayUErrorCode.invalidInput.code,
          message: 'Missing required payment options or altTxnId.',
        ));
        return;
      }

      _currentTxnId =
          altTxnId; // Set the transaction ID for the current payment

      // Ensure _checkoutPro is initialized
      _checkoutPro ??= PayUCheckoutProFlutter(this);

      log('Processing payment for txnId: $_currentTxnId with options: $transactionDetails');

      // Prepare payment parameters
      final Map<String, dynamic> paymentParams = {
        PayUPaymentParamKey.key: transactionDetails['key'],
        PayUPaymentParamKey.amount: transactionDetails['amount'].toString(),
        PayUPaymentParamKey.productInfo: transactionDetails['productinfo'],
        PayUPaymentParamKey.firstName: transactionDetails['firstname'],
        PayUPaymentParamKey.email: transactionDetails['email'],
        PayUPaymentParamKey.phone: transactionDetails['phone'],
        PayUPaymentParamKey.environment:
            mode == 'sandbox' ? _environmentTest : _environmentProduction,
        PayUPaymentParamKey.transactionId: _currentTxnId,
        PayUPaymentParamKey.android_surl: transactionDetails['surl'],
        PayUPaymentParamKey.android_furl: transactionDetails['furl'],
        PayUPaymentParamKey.ios_surl: transactionDetails['surl'],
        PayUPaymentParamKey.ios_furl: transactionDetails['furl'],
        PayUPaymentParamKey.userCredential:
            "${transactionDetails['key']}:${transactionDetails['email']}",
        // Add other optional params like udf1-udf5 if needed
      };

      // Prepare enforced payment methods
      final List<Map<String, String>> enforcePaymentList = [];
      final String? enforcePayMethod =
          transactionDetails['enforce_paymethod'] as String?;
      if (enforcePayMethod != null) {
        final String? payuMethod = _getPayUMethod(enforcePayMethod);
        if (payuMethod != null) {
          enforcePaymentList.add({'payment_type': payuMethod});
        } else {
          log('Warning: Unknown enforce_paymethod value: $enforcePayMethod');
        }
      }

      // Prepare checkout configuration
      final Map<String, dynamic> checkoutConfig = {
        PayUCheckoutProConfigKeys.merchantName: _merchantName, // Use constant
        PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: true,
        if (enforcePaymentList.isNotEmpty)
          PayUCheckoutProConfigKeys.enforcePaymentList: enforcePaymentList,
        // Add other config options like merchantLogo, timeoutDuration etc.
      };

      // Open checkout screen
      _checkoutPro!.openCheckoutScreen(
        payUPaymentParams: paymentParams,
        payUCheckoutProConfig: checkoutConfig,
      );
    } catch (e, stackTrace) {
      log('Error processing payment: $e', stackTrace: stackTrace);
      _handleError(PaymentError(
        code: PayUErrorCode.processingError.code,
        message: 'Payment processing failed: ${e.toString()}',
      ));
    }
  }

  String? _getPayUMethod(String methodKey) {
    const Map<String, String> paymentMethodMap = {
      'netbanking': _netbankingMethod,
      'cashcard': _walletMethod,
      'debitcard': _debitCardMethod,
      'creditcard': _debitCardMethod,
      'upi': _upiMethod,
    };
    return paymentMethodMap[methodKey.toLowerCase()];
  }

  /// Generates hash for PayU payment verification.
  @override
  Future<void> generateHash(Map response) async {
    if (_currentTxnId == null) {
      log('Transaction ID is null. Cannot generate hash.');
      _handleError(PaymentError(
        code: PayUErrorCode.missingTransactionId.code,
        message: 'Transaction ID is missing for hash generation.',
      ));
      // Do not call dispose() here, as it might be an intermediary error.
      // The SDK might expect a hashGenerated or an error callback.
      // Informing PayU about the failure to generate hash.
      _checkoutPro?.hashGenerated(
          hash: {"error": "Hash generation failed: Missing TxnId"});
      return;
    }

    try {
      final hashResponse = await _hashService.generateHashForTransaction(
        txnId: _currentTxnId!,
        response:
            response, // This 'response' is the data from PayU SDK for which hash is needed
      );
      log('Hash generated for txnId: $_currentTxnId, response: $hashResponse');
      _checkoutPro?.hashGenerated(hash: hashResponse);
    } catch (e, stackTrace) {
      log('Error generating hash for txnId: $_currentTxnId: $e',
          stackTrace: stackTrace);
      _handleError(PaymentError(
        code: PayUErrorCode.hashGenerationFailed.code,
        message: 'Hash generation failed: $e',
      ));
      // Inform PayU about the failure to generate hash
      _checkoutPro
          ?.hashGenerated(hash: {"error": "Hash generation failed: $e"});
    }
  }

  /// Handles successful payment response from PayU SDK.
  @override
  void onPaymentSuccess(dynamic response) {
    log('Payment success for txnId: $_currentTxnId, Response: $response');
    if (_onSuccess != null) {
      final Map<String, dynamic> responseMap = _parseResponse(response);
      _onSuccess!(
        PaymentResponse(
          paymentId: _currentTxnId ??
              responseMap['txnid'] ??
              '', // Fallback to response txnid
          rawResponse: responseMap,
          // You might want to extract more structured data from responseMap here
        ),
      );
    }
    _cleanupAfterTransaction();
  }

  /// Handles payment failure response from PayU SDK.
  @override
  void onPaymentFailure(dynamic response) {
    log('Payment failure for txnId: $_currentTxnId, Response: $response');
    if (_onError != null) {
      final Map<String, dynamic> responseMap = _parseResponse(response);
      final String message =
          responseMap['error_Message'] ?? // PayU sometimes uses 'error_Message'
              responseMap['errorMessage'] ??
              responseMap['error'] ??
              'Payment failed';
      _handleError(
          PaymentError(
            code: PayUErrorCode.paymentFailed.code, // More specific code
            message: message,
            rawError: responseMap, // Store the raw error for debugging
          ),
          isSdkCallback: true);
    }
    _cleanupAfterTransaction();
  }

  /// Handles payment cancellation by the user.
  @override
  void onPaymentCancel(dynamic isTxnInitiated) {
    // Parameter name based on PayU docs
    log('Payment cancelled by user for txnId: $_currentTxnId, Is Txn Initiated: $isTxnInitiated');
    if (_onError != null) {
      _handleError(
          PaymentError(
              code: PayUErrorCode.userCancelled.code, // More specific code
              message: 'Payment cancelled by user.',
              rawError: isTxnInitiated),
          isSdkCallback: true);
    }
    _cleanupAfterTransaction();
  }

  /// Handles errors reported by the PayU SDK.
  @override
  void onError(dynamic response) {
    log('SDK Error for txnId: $_currentTxnId, Response: $response');
    if (_onError != null) {
      final Map<String, dynamic> responseMap = _parseResponse(response);
      final String message = responseMap['errorMsg'] ??
          responseMap['errorMessage'] ??
          responseMap['error'] ??
          'Payment processing error';
      final int code = responseMap['errorCode'] as int? ??
          PayUErrorCode.sdkError.code; // More specific
      _handleError(
          PaymentError(
            code: code,
            message: message,
            rawError: responseMap, // Store the raw error for debugging
          ),
          isSdkCallback: true);
    }
    _cleanupAfterTransaction();
  }

  Map<String, dynamic> _parseResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    } else if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    // If it's a string, try to parse as JSON (though PayU usually sends Maps)
    // else return an empty map or a map with the response toString()
    return {'response_data': response.toString()};
  }

  /// Centralized error handling.
  void _handleError(PaymentError error, {bool isSdkCallback = false}) {
    _onError?.call(error);
    if (!isSdkCallback) {
      // If error is not from SDK callback e.g. internal validation,
      // we might not need to cleanup SDK resources yet.
      // However, if it's a critical failure before SDK call, cleanup might be needed.
      log('Handling error: $error');
      _cleanupAfterTransaction();
    }
  }

  /// Cleans up resources after a transaction attempt.
  void _cleanupAfterTransaction() {
    // Don't nullify _checkoutPro here if it can be reused for subsequent transactions.
    // Only nullify if it's single-use or if dispose() is meant to permanently disable.
    // _onSuccess and _onError are transaction-specific, so they can be cleared.
    // _currentTxnId should be cleared to prevent accidental reuse.
    _currentTxnId = null;
  }

  /// Disposes of the PayU service resources.
  /// Call this when the service is no longer needed, e.g., in a widget's dispose method.
  @override
  void dispose() {
    log('Disposing PayUService.');
    _checkoutPro = null;
    _onSuccess = null;
    _onError = null;
    _currentTxnId = null;
  }
}

/// Defines specific error codes for PayU interactions.
/// This makes error handling more granular and easier to manage.
enum PayUErrorCode {
  invalidInput(-4, "Invalid input parameters."),
  missingTransactionId(-5, "Transaction ID is missing."),
  hashGenerationFailed(-6, "Hash generation failed."),
  processingError(-7, "Payment processing failed."),
  paymentFailed(-1, "Payment failed as reported by PayU."),
  userCancelled(-2, "Payment cancelled by user."),
  sdkError(-3, "An error occurred within the PayU SDK."),
  unknown(-99, "An unknown error occurred.");

  const PayUErrorCode(this.code, this.defaultMessage);
  final int code;
  final String defaultMessage;
}
