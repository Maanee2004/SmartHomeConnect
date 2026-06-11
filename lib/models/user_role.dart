/// Rôle applicatif stocké dans `users/{userId}.role`.
class UserRole {
  UserRole._();

  /// Administrateur : gestion globale, interface admin au login.
  static const admin = 'admin';

  /// Utilisateur standard : consultation + commandes (ON/OFF), pas de CRUD structure.
  static const user = 'user';

  static const values = {admin, user};

  static bool isAdmin(String? role) =>
      role?.trim().toLowerCase() == admin;

  static String normalize(String? raw) {
    final r = raw?.trim().toLowerCase();
    if (r == admin) return admin;
    return user;
  }
}
