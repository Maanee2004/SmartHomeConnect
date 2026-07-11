/// Rôle applicatif stocké dans `users/{userId}.role`.
class UserRole {
  UserRole._();

  /// Administrateur plateforme : gestion globale, interface admin au login.
  static const admin = 'admin';

  /// Propriétaire de maison : interface utilisateur + CRUD sur sa maison.
  static const owner = 'owner';

  /// Membre / invité : consultation + commandes ON/OFF, pas de CRUD structure.
  static const user = 'user';

  static const values = {admin, owner, user};

  static bool isAdmin(String? role) =>
      role?.trim().toLowerCase() == admin;

  static bool isOwner(String? role) =>
      role?.trim().toLowerCase() == owner;

  static bool isUser(String? role) {
    final r = role?.trim().toLowerCase();
    return r == null || r.isEmpty || r == user;
  }

  static String normalize(String? raw) {
    final r = raw?.trim().toLowerCase();
    if (r == admin) return admin;
    if (r == owner) return owner;
    return user;
  }

  static String label(String? role) {
    if (isAdmin(role)) return 'Administrateur';
    if (isOwner(role)) return 'Propriétaire';
    return 'Utilisateur';
  }
}
