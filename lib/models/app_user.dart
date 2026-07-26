import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firestore_schema.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.role = UserRole.user,
    this.houseOwnerUserId,
    this.ownedHouseId,
    this.memberHouseId,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;

  /// `admin`, `owner` ou `user` (défaut).
  final String role;

  /// Legacy : propriétaire dont on rejoint la maison via code.
  final String? houseOwnerUserId;

  /// Maison gérée (doc `maisons/{ownedHouseId}`), si différente de [userId].
  final String? ownedHouseId;

  /// Maison consultée en tant qu’invité (assignation admin ou directe).
  final String? memberHouseId;

  final DateTime? createdAt;

  bool get isAdmin => UserRole.isAdmin(role);

  bool get isOwner => UserRole.isOwner(role);

  /// Propriétaire (rôle `owner` assigné par l’admin).
  bool get isHouseOwner => !isMemberOfAnotherHouse && isOwner;

  bool get isMemberOfAnotherHouse =>
      (memberHouseId != null && memberHouseId!.isNotEmpty) ||
      (houseOwnerUserId != null && houseOwnerUserId!.isNotEmpty);

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();
    final owner = (data['houseOwnerUserId'] as String?)?.trim();
    final owned = (data[FirestoreSchema.fieldOwnedHouseId] as String?)?.trim();
    final memberHouse =
        (data[FirestoreSchema.fieldMemberHouseId] as String?)?.trim();
    return AppUser(
      userId: id,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      passwordHash: (data['password'] as String?) ?? '',
      role: UserRole.normalize(data['role'] as String?),
      houseOwnerUserId:
          owner != null && owner.isNotEmpty ? owner : null,
      ownedHouseId: owned != null && owned.isNotEmpty ? owned : null,
      memberHouseId:
          memberHouse != null && memberHouse.isNotEmpty ? memberHouse : null,
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
        if (ownedHouseId != null && ownedHouseId!.isNotEmpty)
          FirestoreSchema.fieldOwnedHouseId: ownedHouseId,
        if (memberHouseId != null && memberHouseId!.isNotEmpty)
          FirestoreSchema.fieldMemberHouseId: memberHouseId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
