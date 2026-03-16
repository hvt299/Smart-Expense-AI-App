import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:smart_expense_ai_app/main.dart';
import 'package:smart_expense_ai_app/providers/auth_provider.dart';

void main() {
  testWidgets('Smoke test: App renders LoginScreen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Expense AI'), findsWidgets);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}
