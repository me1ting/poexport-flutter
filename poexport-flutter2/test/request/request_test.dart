// Import the test package and Counter class
import 'package:cn_poe_export/request/request.dart';
import 'package:cn_poe_export/request/type.dart';
import 'package:test/test.dart';

import '../profile.dart';

void main() {
  test('Request characters', () async {
    final requester = Requester(poeSessId);
    var chacacters = await requester.getCharacters("盲将盲将", "pc");
    expect(chacacters.isNotEmpty, true);
  });

  test('Request characters when logout', () async {
    final requester = Requester("123");
    try {
      await requester.getCharacters("盲将盲将", "pc");
    } on RequestException catch (e) {
      expect(e.errorType, RequestErrorType.forbidden);
    }
  });
}
