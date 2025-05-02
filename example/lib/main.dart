import 'package:flutter/material.dart';
import 'package:ks_pay/ks_pay.dart';

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

    // Use the signature from the text field
    final String signature = _signatureController.text.trim();
    if (signature.isEmpty) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Error: Signature cannot be empty';
      });
      return;
    }

    await ksPay.initialize(
      signature: signature,
    );

    await ksPay.startPayment(
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
