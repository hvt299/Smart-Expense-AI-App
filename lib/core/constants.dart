class AppConstants {
  static const List<String> defaultExpenseCategories = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Hóa đơn',
    'Khác',
  ];

  static const List<String> defaultIncomeCategories = [
    'Lương',
    'Thưởng',
    'Freelance',
    'Kinh doanh',
    'Khác',
  ];

  static String getDefaultAvatar(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random';
  }
}
