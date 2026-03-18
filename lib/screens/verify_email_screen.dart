import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;

  Timer? _checkEmailTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      _checkEmailTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );

      _startCountdown();
    }
  }

  @override
  void dispose() {
    _checkEmailTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      isEmailVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });
    if (isEmailVerified) _checkEmailTimer?.cancel();
  }

  void _startCountdown() {
    setState(() {
      canResendEmail = false;
      _countdownSeconds = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          canResendEmail = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> sendVerificationEmail() async {
    setState(() => _message = null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      if (!mounted) return;
      setState(() {
        _message = 'Đã gửi lại email xác thực! Vui lòng kiểm tra hộp thư.';
        _isError = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Chưa thể gửi lại lúc này. Vui lòng đợi hoặc thử lại sau!';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) return const HomeScreen();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Xác thực Email',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kiểm tra hộp thư của bạn',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chúng tôi đã gửi một liên kết xác thực đến email của bạn. Vui lòng nhấp vào liên kết đó (và kiểm tra cả mục Spam) để kích hoạt tài khoản.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              if (_message != null) ...[
                const SizedBox(height: 24),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isError ? Colors.red : Colors.green.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 32),
              ],

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  icon: canResendEmail
                      ? const Icon(Icons.send_rounded, size: 18)
                      : const SizedBox.shrink(),
                  label: Text(
                    canResendEmail
                        ? 'Gửi lại Email'
                        : 'Gửi lại Email ($_countdownSeconds s)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: canResendEmail ? sendVerificationEmail : null,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                  child: const Text(
                    'Hủy / Đăng xuất',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
