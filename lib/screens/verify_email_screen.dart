import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ok = await auth.resendVerification(widget.email);
      if (!mounted) return;
      setState(() {
        _message = ok
            ? 'Đã gửi lại email xác thực. Vui lòng kiểm tra hộp thư của bạn.'
            : (auth.errorMessage ?? 'Gửi lại email thất bại.');
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Vui lòng xác thực email để tiếp tục',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi đã gửi liên kết xác thực tới:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(color: Colors.blue.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _resend,
              icon: const Icon(Icons.refresh),
              label: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi lại email xác thực'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Tôi đã xác thực - Đăng nhập'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
