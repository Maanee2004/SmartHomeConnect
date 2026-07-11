import 'package:cloud_firestore/cloud_firestore.dart';

/// Invitation à rejoindre une maison via un code à 5 chiffres.
class HouseInvite {
  const HouseInvite({
    required this.inviteId,
    required this.code,
    required this.ownerUserId,
    required this.label,
    required this.revoked,
    required this.usedCount,
    this.createdAt,
    this.expiresAt,
    this.usedByUserIds = const [],
    this.isPrimary = false,
  });

  final String inviteId;
  final String code;
  final String ownerUserId;
  final String label;
  final bool revoked;
  final int usedCount;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> usedByUserIds;

  /// Code principal généré à la création de la maison (non révoquable facilement).
  final bool isPrimary;

  bool get isActive {
    if (revoked) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  factory HouseInvite.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? at(Timestamp? ts) => ts?.toDate();

    final usedRaw = data['usedByUserIds'];
    final used = <String>[
      if (usedRaw is List)
        for (final item in usedRaw)
          if (item is String && item.trim().isNotEmpty) item.trim(),
    ];

    return HouseInvite(
      inviteId: id,
      code: (data['code'] as String?)?.trim() ?? '',
      ownerUserId: (data['ownerUserId'] as String?)?.trim() ?? '',
      label: (data['label'] as String?)?.trim().isNotEmpty == true
          ? (data['label'] as String).trim()
          : 'Invitation',
      revoked: data['revoked'] == true,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? used.length,
      createdAt: at(data['createdAt'] as Timestamp?),
      expiresAt: at(data['expiresAt'] as Timestamp?),
      usedByUserIds: used,
      isPrimary: data['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'code': code,
        'ownerUserId': ownerUserId,
        'label': label,
        'revoked': false,
        'usedCount': 0,
        'usedByUserIds': <String>[],
        'isPrimary': isPrimary,
        'createdAt': FieldValue.serverTimestamp(),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      };
}
