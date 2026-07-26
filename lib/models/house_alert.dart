import 'package:cloud_firestore/cloud_firestore.dart';

/// Alerte maison — `maisons/{userId}/alerts/{alertId}`.
class HouseAlert {
  const HouseAlert({
    required this.alertId,
    required this.type,
    required this.title,
    required this.message,
    this.piece,
    this.appareilId = '',
    this.sourceValue = '',
    this.severity = 'medium',
    this.read = false,
    this.createdAt,
  });

  final String alertId;
  final String type;
  final String title;
  final String message;
  final String? piece;
  final String appareilId;
  final String sourceValue;
  final String severity;
  final bool read;
  final DateTime? createdAt;

  factory HouseAlert.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();

    return HouseAlert(
      alertId: id,
      type: (data['type'] as String?)?.trim() ?? 'unknown',
      title: (data['title'] as String?)?.trim() ?? 'Alerte',
      message: (data['message'] as String?)?.trim() ?? '',
      piece: (data['piece'] as String?)?.trim(),
      appareilId: (data['appareilId'] as String?)?.trim() ?? '',
      sourceValue: (data['sourceValue']?.toString() ?? '').trim(),
      severity: (data['severity'] as String?)?.trim() ?? 'medium',
      read: data['read'] as bool? ?? false,
      createdAt: at,
    );
  }

  Map<String, dynamic> toCreatePayload({required String userId}) => {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        if (piece != null && piece!.isNotEmpty) 'piece': piece,
        'appareilId': appareilId,
        'sourceValue': sourceValue,
        'severity': severity,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

  String get typeLabel => switch (type) {
        'intrusion' => 'Intrusion',
        'temperature' => 'Température',
        'rfid_denied' => 'Badge refusé',
        'distance' => 'Distance',
        'humidity' => 'Humidité',
        _ => 'Alerte',
      };
}
