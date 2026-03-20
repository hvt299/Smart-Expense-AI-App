import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;
      _termsError = false;
    });
  }

  Future<void> _submit() async {
    _clearErrors();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    if (!_isLoginMode && name.isEmpty) {
      setState(() => _nameError = 'Vui lòng nhập Họ và tên');
      if (!hasError) _nameFocus.requestFocus();
      hasError = true;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập Email');
      if (!hasError) _emailFocus.requestFocus();
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Email không đúng định dạng');
      if (!hasError) _emailFocus.requestFocus();
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng nhập Mật khẩu');
      if (!hasError) _passwordFocus.requestFocus();
      hasError = true;
    } else {
      final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])[A-Za-z\d\W_]{8,}$',
      );
      if (!_isLoginMode && !passwordRegex.hasMatch(password)) {
        setState(() => _passwordError = 'Mật khẩu chưa đủ mạnh');
        if (!hasError) _passwordFocus.requestFocus();
        hasError = true;
      }
    }

    if (!_isLoginMode) {
      if (confirmPassword.isEmpty) {
        setState(() => _confirmError = 'Vui lòng nhập lại mật khẩu');
        if (!hasError) _confirmFocus.requestFocus();
        hasError = true;
      } else if (password != confirmPassword) {
        setState(() => _confirmError = 'Mật khẩu không khớp!');
        if (!hasError) _confirmFocus.requestFocus();
        hasError = true;
      }
    }

    if (!_isLoginMode && !_acceptedTerms) {
      setState(() => _termsError = true);
      hasError = true;
    }

    if (hasError) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLoginMode) {
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        await authService.signUpWithEmailAndPassword(email, password, name);
      }
    } catch (e) {
      setState(
        () => _generalError = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    _clearErrors();
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(
        () => _generalError = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Smart Expense AI',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode
                        ? 'Chào mừng bạn trở lại! 👋'
                        : 'Bắt đầu quản lý tài chính ngay 🚀',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isLoginMode) ...[
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() => _nameError = null),
                      decoration: InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: const Icon(Icons.person_outline, size: 22),
                        errorText: _nameError,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() => _emailError = null),
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: const Icon(Icons.email_outlined, size: 22),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: _isLoginMode
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onChanged: (_) => setState(() => _passwordError = null),
                    onSubmitted: _isLoginMode
                        ? (_) => _submit()
                        : (_) => FocusScope.of(
                            context,
                          ).requestFocus(_confirmFocus),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 22),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  if (!_isLoginMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 12.0,
                        right: 12.0,
                      ),
                      child: Text(
                        '💡 Tối thiểu 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  if (_isLoginMode) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() => _confirmError = null),
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Nhập lại mật khẩu *',
                        prefixIcon: const Icon(Icons.lock_reset, size: 22),
                        errorText: _confirmError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _acceptedTerms,
                            isError: _termsError,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                                _termsError = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Smart Expense AI.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: _termsError
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_generalError != null) ...[
                    Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      alignment: Alignment.center,
                      child: Text(
                        _generalError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const FaIcon(
                        FontAwesomeIcons.google,
                        color: Color(0xFFDB4437),
                        size: 18,
                      ),
                      label: const Text(
                        'Tiếp tục với Google',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitGoogle,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode
                            ? 'Chưa có tài khoản?'
                            : 'Đã có tài khoản?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                  _clearErrors();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                        child: Text(
                          _isLoginMode ? 'Đăng ký ngay' : 'Đăng nhập',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
