import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ks_pay/ks_pay.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KS Pay Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PaymentScreen(),
    );
  }
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

  final KsPay ksPay = KsPay.instance;

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _paymentStatus = 'Processing...';
    });
    await getSignature();

    // Use the signature from the text field
    final String signature = _signatureController.text.trim();
    if (signature.isEmpty) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Error: Signature cannot be empty';
      });
      return;
    }

    await ksPay.startPayment(
      signature: signature,
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

  Future<void> getSignature() async {
    String reference = generateUniqueString(16);
    final url =
        Uri.parse('https://qa-ks-pay-openapi.p2eppl.com/transaction/initiate');
    final result = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accessKey': 'kspay_test_bfc4af6909b9f6b86a5ca688',
        'secretKey':
            '8fd79d440910907d041d059a07d558251f27b917bd850535885b66879a2611a6',
      },
      body: json.encode({
        "currencyId": "c_p4VJNYJPhK",
        // "paymentMethodId": null,
        "amount": 1,
        "referenceNumber": reference,
        "appId": "ap_1Xp0qtsS2",
        "redirectUrl": "https://sparkling-alfajores-df7506.netlify.app/success",
        "interfaceType": "sdk"
      }),
    );

    final signature = json.decode(result.body);

    setState(() {
      _signatureController.text = signature['result'];
    });
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Payment Status:',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_paymentStatus),
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
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _processPayment,
                  child: const Text('Make Payment'),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
