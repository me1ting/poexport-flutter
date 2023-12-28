import 'dart:convert';
import 'dart:io';

import 'package:cn_poe_export/basic/logger.dart';
import 'package:http/http.dart' as http;

import 'type.dart';

const cnPoeForumHost = "poe.game.qq.com";
const profilePath = "/api/profile";
const getCharactersPath = "/character-window/get-characters";
const viewProfilePath = "/account/view-profile";
const getPassiveSkillsPath = "/character-window/get-passive-skills";
const getItemsPath = "/character-window/get-items";

var profileUri = Uri.https(cnPoeForumHost, profilePath);
var getCharactersUri = Uri.https(cnPoeForumHost, getCharactersPath);
var getPassiveSkillsUri = Uri.https(cnPoeForumHost, getPassiveSkillsPath);
var getItemsUri = Uri.https(cnPoeForumHost, getItemsPath);

/// The POE api-requested [http.Client].
///
/// Request with POESESSID and disable redirect.
class _PoeClient extends http.BaseClient {
  final String _poeSessId;
  final _inner = http.Client();

  _PoeClient(this._poeSessId);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Cookie'] = "POESESSID=$_poeSessId";
    //TODO: fix redirect diabled does not work
    request.followRedirects = false;

    logger.i("${request.method} ${request.url}");

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Global single instance of Requester.
///
/// Init it by setting poessid.
final requester = Requester("");

class Requester {
  _PoeClient _client;

  set poeSessId(String poeSessId) {
    _client.close();
    _client = _PoeClient(poeSessId);
  }

  Requester(String poeSessId) : _client = _PoeClient(poeSessId);

  /// Request profile data.
  ///
  /// throws [http.ClientException] when a network error occurs.
  /// throws [RequestException] when a server error is recived.
  Future<Profile> profile() async {
    var resp = await _client.get(profileUri);

    var respBody = resp.body;
    var contentType = resp.headers["content-type"];
    if (contentType == null || !contentType.contains("charset")) {
      respBody = utf8.decode(resp.bodyBytes);
    }

    logger.i("${resp.statusCode} $respBody");

    if (resp.statusCode == HttpStatus.ok) {
      Map<String, dynamic> data = jsonDecode(respBody);
      var profile = Profile.fromJson(data);
      return profile;
    } else {
      if (_isHtml(resp.body)) {
        throw RequestException.fromStatusCode(resp.statusCode);
      }

      Map<String, dynamic> dataMap = jsonDecode(resp.body);
      var error = ReturnedError.fromJson(dataMap["error"]);

      throw RequestException.fromReturnedError(resp.statusCode, error);
    }
  }

  /// Get characters data of an account.
  ///
  /// Throw [http.ClientException] when a network error occurs.
  ///
  /// Throw [RequestException] when a server error is recived.
  Future<List<Character>> getCharacters(
      String accountName, String realm) async {
    var formData = <String, dynamic>{};
    formData["accountName"] = accountName;
    formData["realm"] = realm;

    logger.i("get characters of $formData");

    // throw [http.ClientException] when a network error occurs
    var resp = await _client.post(getCharactersUri, body: formData);

    var respBody = resp.body;
    var contentType = resp.headers["content-type"];
    if (contentType == null || !contentType.contains("charset")) {
      respBody = utf8.decode(resp.bodyBytes);
    }

    logger.i("${resp.statusCode} $respBody");

    if (resp.statusCode == HttpStatus.ok) {
      List<dynamic> data = jsonDecode(respBody);
      List<Character> characters = [];
      for (Map<String, dynamic> item in data) {
        characters.add(Character.fromJson(item));
      }
      return characters;
    } else {
      if (_isHtml(respBody)) {
        throw RequestException.fromStatusCode(resp.statusCode);
      }

      Map<String, dynamic> dataMap = jsonDecode(resp.body);
      var error = ReturnedError.fromJson(dataMap["error"]);
      throw RequestException.fromReturnedError(resp.statusCode, error);
    }
  }

  /// Get passive skills json of a character.
  ///
  /// Throw [http.ClientException] when a network error occurs.
  ///
  /// Throw [RequestException] when a server error is recived.
  Future<String> getPassiveSkills(
      String accountName, String character, String realm) async {
    var formData = <String, dynamic>{};
    formData["accountName"] = accountName;
    formData["character"] = character;
    formData["realm"] = realm;

    logger.i("get passive skills of $formData");

    /// throw [http.ClientException] when a network error occurs
    var resp = await _client.post(getPassiveSkillsUri, body: formData);

    var respBody = resp.body;
    var contentType = resp.headers["content-type"];
    if (contentType == null || !contentType.contains("charset")) {
      respBody = utf8.decode(resp.bodyBytes);
    }

    logger.i("${resp.statusCode} $respBody");

    if (resp.statusCode == HttpStatus.ok) {
      return respBody;
    } else {
      if (_isHtml(respBody)) {
        throw RequestException.fromStatusCode(resp.statusCode);
      }

      Map<String, dynamic> dataMap = jsonDecode(resp.body);
      var error = ReturnedError.fromJson(dataMap["error"]);
      throw RequestException.fromReturnedError(resp.statusCode, error);
    }
  }

  /// Get items json of a character.
  ///
  /// Throw [http.ClientException] when a network error occurs.
  ///
  /// Throw [RequestException] when a server error is recived.
  Future<String> getItems(
      String accountName, String character, String realm) async {
    var formData = <String, dynamic>{};
    formData["accountName"] = accountName;
    formData["character"] = character;
    formData["realm"] = realm;

    logger.i("get items of $formData");

    http.Response resp = await _client.post(getItemsUri, body: formData);

    var respBody = resp.body;
    var contentType = resp.headers["content-type"];
    if (contentType == null || !contentType.contains("charset")) {
      respBody = utf8.decode(resp.bodyBytes);
    }

    logger.i("${resp.statusCode} $respBody");

    if (resp.statusCode == HttpStatus.ok) {
      return respBody;
    } else {
      if (_isHtml(respBody)) {
        throw RequestException.fromStatusCode(resp.statusCode);
      }

      Map<String, dynamic> dataMap = jsonDecode(resp.body);
      var error = ReturnedError.fromJson(dataMap["error"]);
      throw RequestException.fromReturnedError(resp.statusCode, error);
    }
  }

  static const doctypeHtml = "<!doctype html>";

  static bool _isHtml(String body) {
    return body.trimLeft().substring(0, doctypeHtml.length).toLowerCase() ==
        doctypeHtml;
  }
}
