import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();
    return AppUser(
      userId: (data['userId'] as String?)?.trim().isNotEmpty == true
          ? (data['userId'] as String).trim()
          : id,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      passwordHash: (data['password'] as String?) ?? '',
      createdAt: at,
    );
  }

  Map<String, dynamic> toCreatePayload({required String passwordHash}) => {
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'password': passwordHash,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
