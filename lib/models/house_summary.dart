/// Maison = utilisateur ayant au moins une pièce ou un appareil.
class HouseSummary {
  const HouseSummary({
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerEmail,
    required this.roomCount,
    required this.deviceCount,
    this.memberUserIds = const [],
  });

  final String ownerUserId;
  final String ownerName;
  final String ownerEmail;
  final int roomCount;
  final int deviceCount;
  final List<String> memberUserIds;

  bool get hasHouse => roomCount > 0 || deviceCount > 0;
}
