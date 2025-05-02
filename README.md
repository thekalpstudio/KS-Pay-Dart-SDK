# KS Pay

A Flutter package to process payments via Razorpay or PayU based on a backend-provided flag. This package simplifies the integration of multiple payment gateways by providing a unified API.

## Features

- Unified API for multiple payment gateways
- Dynamic gateway selection based on backend configuration
- Support for Razorpay and PayU payment gateways
- Simple callback-based success and error handling
- Automatic handling of gateway-specific details

## Getting started

### Prerequisites

1. Ensure you have Flutter installed and set up.
2. For Razorpay integration, you need to have a Razorpay account and API keys.
3. For PayU integration, you need to have a PayU account and API keys.

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  ks_pay: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Platform-specific setup

#### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS

Add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Usage

### Basic Usage

```dart
import 'package:ks_pay/ks_pay.dart';

// Process a payment
await KsPay.processPayment(
  orderToken: 'your_order_token',
  backendUrl: 'https://api.yourdomain.com/payment/init',
  onSuccess: (response) {
    print('Payment successful: ${response.paymentId}');
    // Handle success
  },
  onError: (error) {
    print('Payment failed: ${error.message}');
    // Handle error
  },
);

// Clean up resources when done
KsPay.dispose();
```

### Backend Response Format

Your backend should return a response in the following format:

```json
{
  "paymentType": "razorpay", // or "payu"
  "options": {
    // Gateway-specific options
    // For Razorpay:
    "key": "rzp_test_1234567890",
    "amount": 50000, // in paise
    "name": "Your Company",
    "description": "Test Payment",
    "prefill": {
      "contact": "9876543210",
      "email": "test@example.com"
    }
    // For PayU, provide appropriate options
  }
}
```

### Handling Cleanup

When you're done with the payment process, make sure to dispose of the resources:

```dart
@override
void dispose() {
  KsPay.dispose();
  super.dispose();
}
```

## Additional information

### Supported Payment Gateways

- Razorpay
- PayU

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.
