class Character {
  Map<String, dynamic> _json;

  Character(this._json);

  String get league => _json["league"]!;
  set league(String val) => _json["league"] = val;

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(json);
  }

  Map<String, dynamic> toJson() {
    return _json;
  }
}
