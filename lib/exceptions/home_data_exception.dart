class DuplicateRoomNameException implements Exception {
  DuplicateRoomNameException(this.displayName);
  final String displayName;
  @override
  String toString() =>
      'Une pièce nommée « $displayName » existe déjà.';
}

class PinAlreadyAssignedException implements Exception {
  PinAlreadyAssignedException(this.pin, {this.existingDeviceId});
  final int pin;
  final String? existingDeviceId;
  @override
  String toString() {
    final who = existingDeviceId != null ? ' ($existingDeviceId)' : '';
    return 'La broche $pin est déjà utilisée$who.';
  }
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
