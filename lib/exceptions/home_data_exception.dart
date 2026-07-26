class DuplicateRoomNameException implements Exception {
  DuplicateRoomNameException(this.displayName);
  final String displayName;
  @override
  String toString() =>
      'Une pièce nommée « $displayName » existe déjà.';
}

class PinAlreadyAssignedException implements Exception {
  PinAlreadyAssignedException(
    this.pin, {
    this.existingDeviceId,
    this.existingDeviceName,
  });
  final int pin;
  final String? existingDeviceId;
  final String? existingDeviceName;

  /// Message pour l’interface (sans id technique si le nom est connu).
  String messageForUser({bool includeTechnicalIds = false}) {
    final name = existingDeviceName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'La broche $pin est déjà utilisée par « $name ».';
    }
    if (includeTechnicalIds && existingDeviceId != null) {
      return 'La broche $pin est déjà utilisée ($existingDeviceId).';
    }
    return 'La broche $pin est déjà utilisée. Choisis une autre broche libre.';
  }

  @override
  String toString() => messageForUser();
}

class AppareilValidationException implements Exception {
  AppareilValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppareilImmutableFieldException implements Exception {
  AppareilImmutableFieldException(this.field);
  final String field;
  @override
  String toString() =>
      'Le champ « $field » (pin, type ou categorie) ne peut pas être modifié.';
}
