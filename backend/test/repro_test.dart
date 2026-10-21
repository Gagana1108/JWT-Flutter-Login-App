import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

void main() {
  test('test bcrypt and jwt', () {
    final salt = BCrypt.gensalt();
    final hash = BCrypt.hashpw('Password123!', salt);
    final check = BCrypt.checkpw('Password123!', hash);
    expect(check, isTrue);

    final jwt = JWT({'sub': '1', 'email': 'test@example.com'});
    final token = jwt.sign(
      SecretKey('super_secret_jwt_key_change_me_in_production_123456789'),
    );
    expect(token.isNotEmpty, isTrue);
  });
}
