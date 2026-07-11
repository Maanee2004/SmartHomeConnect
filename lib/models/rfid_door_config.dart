import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/rfid_card.dart';

/// Lecteur RFID + badges autorisés (+ porte liée éventuelle).
class RfidReaderConfig {
  const RfidReaderConfig({
    required this.reader,
    required this.badges,
    this.linkedServo,
  });

  final Device reader;
  final List<RfidCard> badges;
  final Device? linkedServo;

  String get readerId => reader.id;

  int get activeBadgeCount => badges.where((b) => b.active).length;

  /// Badges explicitement liés au lecteur ou via la porte associée.
  static List<RfidCard> badgesForReader({
    required Device reader,
    required List<RfidCard> cards,
    required List<Device> servos,
  }) {
    final doorIds = servos
        .where((s) => s.rfidCible == reader.id)
        .map((s) => s.id)
        .toSet();

    return cards.where((c) {
      if (c.readerId == reader.id) return true;
      if (c.readerId != null && c.readerId!.isNotEmpty) return false;
      if (c.servoId != null && doorIds.contains(c.servoId)) return true;
      return false;
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  static List<RfidReaderConfig> build({
    required List<Device> devices,
    required List<RfidCard> cards,
  }) {
    final readers =
        devices.where((d) => d.normalizedType == 'RFID').toList();
    final servos =
        devices.where((d) => d.normalizedType == 'SERVO').toList();

    return [
      for (final reader in readers)
        RfidReaderConfig(
          reader: reader,
          badges: badgesForReader(reader: reader, cards: cards, servos: servos),
          linkedServo: servos.cast<Device?>().firstWhere(
                (s) => s?.rfidCible == reader.id,
                orElse: () => null,
              ),
        ),
    ];
  }
}

/// Porte (SERVO) + lecteur RFID lié + badges autorisés.
class RfidDoorConfig {
  const RfidDoorConfig({
    required this.servo,
    this.linkedReader,
    required this.badges,
  });

  final Device servo;
  final Device? linkedReader;
  final List<RfidCard> badges;

  String get servoId => servo.id;

  int get activeBadgeCount => badges.where((b) => b.active).length;

  static List<RfidDoorConfig> build({
    required List<Device> devices,
    required List<RfidCard> cards,
  }) {
    final servos =
        devices.where((d) => d.normalizedType == 'SERVO').toList();
    final readersById = {
      for (final r in devices.where((d) => d.normalizedType == 'RFID'))
        r.id: r,
    };

    return [
      for (final servo in servos)
        RfidDoorConfig(
          servo: servo,
          linkedReader: readersById[servo.rfidCible ?? ''],
          badges: cards.where((c) => c.servoId == servo.id).toList(),
        ),
    ];
  }

  static List<RfidCard> unassignedBadges(List<RfidCard> cards) =>
      cards
          .where(
            (c) =>
                (c.servoId == null || c.servoId!.isEmpty) &&
                (c.readerId == null || c.readerId!.isEmpty),
          )
          .toList();

  static List<Device> unlinkedReaders(List<Device> devices) {
    final linkedIds = devices
        .where((d) => d.normalizedType == 'SERVO')
        .map((s) => s.rfidCible)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    return devices
        .where(
          (d) => d.normalizedType == 'RFID' && !linkedIds.contains(d.id),
        )
        .toList();
  }
}
