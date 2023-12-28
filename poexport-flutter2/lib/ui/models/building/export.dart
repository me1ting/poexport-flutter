import 'dart:collection';

import 'package:cn_poe_export/request/type.dart';
import 'package:flutter/foundation.dart';

class SimpleExportModel extends ChangeNotifier {
  String? _accountName;
  String? loadedAccountName;
  List<String>? leagues;
  List<Character>? _characters;
  List<String>? shownCharacterNames;

  String? _league;
  String? _characterName;
  String? _code;

  String? get accountName {
    return _accountName;
  }

  set accountName(String? value) {
    _accountName = value;
    notifyListeners();
  }

  List<Character>? get characters => _characters;
  set characters(List<Character>? value) {
    _characters = value;
    if (value == null) {
      leagues = null;
    } else {
      leagues = LinkedHashSet<String>.from(value.map((e) => e.league).toList())
          .toList();
    }
    _league = leagues?.first;
    shownCharacterNames = _characters
        ?.where((c) => c.league == _league)
        .map((e) => e.name)
        .toList();
    _characterName = shownCharacterNames?.first;
    notifyListeners();
  }

  String? get league => _league;
  set league(String? value) {
    _league = value;
    if (value == null) {
      _characterName = null;
    } else {
      shownCharacterNames = _characters
          ?.where((c) => c.league == _league)
          .map((e) => e.name)
          .toList();
      _characterName = shownCharacterNames?.first;
    }
    notifyListeners();
  }

  String? get characterName => _characterName;
  set characterName(String? value) {
    _characterName = value;
    notifyListeners();
  }

  String? get code => _code;
  set code(String? value) {
    _code = value;
    notifyListeners();
  }
}
