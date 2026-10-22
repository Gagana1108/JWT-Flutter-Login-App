import 'package:flutter_test/flutter_test.dart';
import 'package:login_jwt/main.dart';
import 'package:login_jwt/providers/auth_provider.dart';
import 'package:login_jwt/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders splash screen correctly', (WidgetTester tester) async {
    final storageService = StorageService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(storageService),
          ),
        ],
        child: const AuthApp(),
      ),
    );

    expect(find.text('Auth App'), findsOneWidget);
    expect(find.text('JWT & MySQL Secure Authentication'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
