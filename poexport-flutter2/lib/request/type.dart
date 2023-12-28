import 'dart:io';

/// Returned error by server.
class ReturnedError {
  int code;
  String message;

  ReturnedError(this.code, this.message);

  ReturnedError.fromJson(Map<String, dynamic> json)
      : code = json["code"],
        message = json["message"];

  @override
  String toString() {
    return "{'code':$code,'message':$message}";
  }

  static const unauthorizedCode = 8;
  static const forbiddenCode = 6;
  static const rateLimitedCode = 3;
}

const unauthorizedStatusCode = 401;
const forbiddenStatusCode = 403;
const notFoundStatusCode = 404;
const rateLimitedStatusCode = 429;

enum RequestErrorType {
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  maintaining,
  unknown;

  static RequestErrorType fromReturnedError(ReturnedError error) {
    return switch (error.code) {
      ReturnedError.unauthorizedCode => RequestErrorType.unauthorized,
      ReturnedError.forbiddenCode => RequestErrorType.forbidden,
      ReturnedError.rateLimitedCode => RequestErrorType.rateLimited,
      _ => RequestErrorType.unknown
    };
  }

  static RequestErrorType fromStatusCode(int statusCode) {
    return switch (statusCode) {
      unauthorizedStatusCode => RequestErrorType.unauthorized,
      forbiddenStatusCode => RequestErrorType.forbidden,
      notFoundStatusCode => RequestErrorType.notFound,
      rateLimitedStatusCode => RequestErrorType.rateLimited,
      _ => RequestErrorType.unknown
    };
  }
}

/// RequestException includes any [RequestError] returned by server.
class RequestException implements Exception {
  final RequestErrorType errorType;

  const RequestException(this.errorType);

  factory RequestException.fromReturnedError(
      int httpStatusCode, ReturnedError error) {
    var type = RequestErrorType.fromReturnedError(error);
    return RequestException(type);
  }

  factory RequestException.fromStatusCode(int statusCode) {
    var type = RequestErrorType.fromStatusCode(statusCode);
    return RequestException(type);
  }

  @override
  String toString() {
    return "RequestException: $errorType";
  }
}

class RateLimitPolicy {
// rate limit policy in http header likes:
//
// X-Rate-Limit-Account: 30:60:60,100:1800:600
// X-Rate-Limit-Account-State: 14:60:0,14:1800:0
// X-Rate-Limit-Ip: 45:60:120,180:1800:600
// X-Rate-Limit-Ip-State: 14:60:0,14:1800:0
// X-Rate-Limit-Policy: backend-item-request-limit
// X-Rate-Limit-Rules: Account,Ip
  String id;
  List<RateLimitRule> rules;

  RateLimitPolicy(this.id, this.rules);

  /// Check wheather a [http.HttpResponse] contains rate limit policy.
  static bool containsPolicy(HttpResponse resp) {
    return resp.headers.value("X-Rate-Limit-Policy") != null ? true : false;
  }

  static RateLimitPolicy? fromResp(HttpResponse resp) {
    var policyId = resp.headers.value("X-Rate-Limit-Policy");
    if (policyId == null) {
      return null;
    }

    var ruleNames = resp.headers.value("X-Rate-Limit-Rules")!;
    var ruleNameList = ruleNames.split(",");

    var rules = <RateLimitRule>[];
    for (final ruleName in ruleNameList) {
      var detailString = resp.headers.value("X-Rate-Limit-$ruleName")!;
      var stateString = resp.headers.value("X-Rate-Limit-$ruleName-State")!;

      var detailSlice = detailString.split(",");
      var stateSlice = stateString.split(",");

      var entries = <(LimitData detail, LimitData state)>[];
      for (var i = 0; i < detailSlice.length; i++) {
        entries.add((
          LimitData.fromHeaderValue(detailSlice[i]),
          LimitData.fromHeaderValue(stateSlice[i])
        ));
      }

      rules.add(RateLimitRule(ruleName, entries));
    }

    return RateLimitPolicy(policyId, rules);
  }
}

class RateLimitRule {
  String ruleName;
  List<(LimitData detail, LimitData state)> entries;

  RateLimitRule(this.ruleName, this.entries);
}

class LimitData {
  int count;
  int cycle;
  int punishment;

  LimitData(this.count, this.cycle, this.punishment);

  factory LimitData.fromHeaderValue(String value) {
    var parts = value.split(":");
    return LimitData(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

class Profile {
  String uuid;
  String name;
  String realm;
  String locale;

  Profile(this.uuid, this.name, this.realm, this.locale);

  Profile.fromJson(Map<String, dynamic> json)
      : uuid = json["uuid"],
        name = json["name"],
        realm = json["realm"],
        locale = json["locale"];
}

class Character {
  String className;
  String league;
  int level;
  String name;
  String realm;

  Character(this.className, this.league, this.level, this.name, this.realm);

  Character.fromJson(Map<String, dynamic> json)
      : className = json["class"],
        league = json["league"],
        level = json["level"],
        name = json["name"],
        realm = json["realm"];
}
