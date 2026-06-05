import 'package:bcrypt/bcrypt.dart';

/// Hachage bcrypt (compatible empreintes type Node.js `$2b$10$…`).
class PasswordHasher {
  PasswordHasher._();

  static String hash(String plain) => BCrypt.hashpw(plain, BCrypt.gensalt());

  static bool verify(String plain, String hashed) {
    if (hashed.isEmpty) return false;
    try {
      return BCrypt.checkpw(plain, hashed);
    } catch (_) {
      return false;
    }
  }
}
