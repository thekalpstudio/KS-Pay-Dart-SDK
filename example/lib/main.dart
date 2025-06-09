import 'package:flutter/material.dart';
import 'package:ks_pay/ks_pay.dart';
import 'package:random_string/random_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KS Pay Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PaymentScreen(),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  PaymentMethod(this.id, this.name);
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentStatus = 'Not started';
  bool _isLoading = false;
  final TextEditingController _signatureController = TextEditingController(
    text: '',
  );

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod('null', 'All'),
    PaymentMethod('pm_otIr9SB6P', 'WALLET'),
    PaymentMethod('pm_MCidJcKGx', 'NET BANKING'),
    PaymentMethod('pm_2pvYs5lEL', 'DEBIT CARD'),
    PaymentMethod('pm_hnztyNEt3', 'CREDIT CARD'),
    PaymentMethod('pm_aVjlZXY5r', 'UPI'),
    PaymentMethod('pm_3TPPxTM15', 'PAY LATER'),
  ];

  String? selectedPaymentMethodId;

  final KsPay ksPay = KsPay.instance;

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _paymentStatus = 'Processing...';
    });

    // Use the signature from the text field
    final String signature = _signatureController.text.trim();
    if (signature.isEmpty) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Please enter a valid signature.';
      });
      return;
    }

    await ksPay.startPayment(
      signature: signature,
      isSandbox: true,
      onSuccess: (response) {
        setState(() {
          _isLoading = false;
          _paymentStatus =
              'Payment successful!\nPayment ID: ${response.paymentId}';
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _paymentStatus = 'Payment failed: ${error.message}';
        });
      },
    );
  }

  String generateUniqueString(int length) {
    return randomAlphaNumeric(length);
  }

  @override
  void dispose() {
    // Clean up resources
    ksPay.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KS Pay Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            'Select Payment Method:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...paymentMethods.map((method) => RadioListTile<String>(
                title: Text(method.name),
                value: method.id,
                groupValue: selectedPaymentMethodId,
                onChanged: (String? value) {
                  setState(() {
                    selectedPaymentMethodId = value;
                  });
                },
              )),
          const SizedBox(height: 20),
          Text(
            'Payment Status:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Text(
              _paymentStatus,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _signatureController,
            decoration: const InputDecoration(
              labelText: 'Signature',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            Center(child: const CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _processPayment,
              child: const Text('Make Payment'),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
