/// Résumé d’une maison Firestore `maisons/{houseId}`.
class HouseSummary {
  const HouseSummary({
    required this.houseId,
    required this.name,
    this.ownerUserId,
    this.ownerName = '',
    this.ownerEmail = '',
    required this.roomCount,
    required this.deviceCount,
    this.memberUserIds = const [],
  });

  /// ID document `maisons/{houseId}`.
  final String houseId;
  final String name;
  final String? ownerUserId;
  final String ownerName;
  final String ownerEmail;
  final int roomCount;
  final int deviceCount;
  final List<String> memberUserIds;

  bool get hasOwner =>
      ownerUserId != null && ownerUserId!.trim().isNotEmpty;

  bool get hasHouse => roomCount > 0 || deviceCount > 0;

  String get displayTitle =>
      name.trim().isNotEmpty ? name.trim() : houseId;

  String get ownerLabel {
    if (!hasOwner) return 'Sans propriétaire';
    if (ownerName.trim().isNotEmpty) return ownerName.trim();
    return ownerUserId!;
  }
}
