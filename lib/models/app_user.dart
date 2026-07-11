import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/user_role.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.role = UserRole.user,
    this.houseOwnerUserId,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;

  /// `admin`, `owner` ou `user` (défaut).
  final String role;

  /// Si renseigné, l’utilisateur consulte la maison de ce propriétaire (lecture).
  final String? houseOwnerUserId;

  final DateTime? createdAt;

  bool get isAdmin => UserRole.isAdmin(role);

  bool get isOwner => UserRole.isOwner(role);

  /// Propriétaire (rôle `owner` assigné par l’admin).
  bool get isHouseOwner =>
      !isMemberOfAnotherHouse && isOwner;

  bool get isMemberOfAnotherHouse =>
      houseOwnerUserId != null && houseOwnerUserId!.isNotEmpty;

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();
    final owner = (data['houseOwnerUserId'] as String?)?.trim();
    return AppUser(
      // Toujours l’ID document Firestore (évite les échecs admin si le champ diverge).
      userId: id,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      passwordHash: (data['password'] as String?) ?? '',
      role: UserRole.normalize(data['role'] as String?),
      houseOwnerUserId:
          owner != null && owner.isNotEmpty ? owner : null,
      createdAt: at,
    );
  }

  Map<String, dynamic> toCreatePayload({required String passwordHash}) => {
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'password': passwordHash,
        'role': role,
        if (houseOwnerUserId != null && houseOwnerUserId!.isNotEmpty)
          'houseOwnerUserId': houseOwnerUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
