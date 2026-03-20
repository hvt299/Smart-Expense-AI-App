import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedGender = 'Khác';
  DateTime? _selectedBirthDate;

  String _avatarUrl = '';
  String _originalAvatar = '';
  bool _isLoading = false;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];
  final List<String> _defaultAvatars = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Liam',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Noah',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Oliver',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Olivia',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Amelia',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Charlotte',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _nameController.text = user.displayName ?? '';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _originalAvatar = data['initialAvatarUrl'] ?? _defaultAvatars.first;
        _avatarUrl = data['avatarUrl'] ?? _originalAvatar;
        _phoneController.text = data['phone'] ?? '';
        _occupationController.text = data['occupation'] ?? '';
        _selectedGender = data['gender'] ?? 'Khác';
        if (data['monthlyBudget'] != null) {
          _budgetController.text = NumberFormat(
            '#,##0',
          ).format(data['monthlyBudget']).replaceAll(',', '.');
        }
        if (data['birthDate'] != null) {
          _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
        }
      });
    } else {
      setState(() {
        _originalAvatar = _defaultAvatars.first;
        _avatarUrl = _originalAvatar;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;

      await user.updateProfile(
        displayName: _nameController.text.trim(),
        photoURL: _avatarUrl,
      );
      await user.reload();

      final budgetStr = _budgetController.text.replaceAll('.', '');
      final budget = double.tryParse(budgetStr) ?? 0;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatarUrl': _avatarUrl,
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'gender': _selectedGender,
        'monthlyBudget': budget,
        'birthDate': _selectedBirthDate != null
            ? Timestamp.fromDate(_selectedBirthDate!)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    final email = user?.email ?? '';
    final createdAt = user?.metadata.creationTime != null
        ? DateFormat('dd/MM/yyyy').format(user!.metadata.creationTime!)
        : '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_avatarUrl),
                            backgroundColor: Colors.grey.shade200,
                          ),

                          if (_avatarUrl != _originalAvatar)
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _avatarUrl = _originalAvatar),
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Khôi phục ảnh gốc'),
                            )
                          else
                            const SizedBox(height: 12),

                          Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            children: _defaultAvatars
                                .map(
                                  (url) => GestureDetector(
                                    onTap: () =>
                                        setState(() => _avatarUrl = url),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _avatarUrl == url
                                              ? Colors.blue
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(url),
                                        backgroundColor: Colors.grey.shade100,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      initialValue: email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: createdAt,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Ngày tham gia',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val!.trim().isEmpty
                          ? 'Họ tên không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Giới tính',
                              prefixIcon: Icon(Icons.wc),
                            ),
                            items: _genders
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGender = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _selectedBirthDate ?? DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedBirthDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngày sinh',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              child: Text(
                                _selectedBirthDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedBirthDate!)
                                    : 'Chưa chọn',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Nghề nghiệp',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Hạn mức chi tiêu tháng',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        suffixText: 'VNĐ',
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveProfile,
                        child: const Text(
                          'LƯU HỒ SƠ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final formatted = NumberFormat('#,##0').format(number).replaceAll(',', '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
