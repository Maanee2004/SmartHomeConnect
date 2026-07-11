import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/services/house_invites_repository.dart';

void main() {
  group('HouseInvitesRepository.generateCode', () {
    test('produit un code à 5 chiffres numériques', () {
      for (var i = 0; i < 50; i++) {
        final code = HouseInvitesRepository.generateCode();
        expect(code.length, 5);
        expect(int.tryParse(code), isNotNull);
        expect(int.parse(code), inInclusiveRange(10000, 99999));
      }
    });
  });
}
