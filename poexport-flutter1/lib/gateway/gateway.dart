import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:poe_cn_export/gateway/types.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../settings/settings.dart';
import '../poe/requester.dart';

const getCharactersUrlPrefix = "character-window/get-characters";
const viewProfileUrlPrefix = "account/view-profile/";
const getPassiveSkillsUrlPrefix = "character-window/get-passive-skills";
const getItemsUrlPrefix = "character-window/get-items";

class Gateway {
  final Requester _requester;
  final SettingsManager _settingsManager;
  final log = Logger('Gateway');

  Gateway(this._requester, this._settingsManager);

  Future<void> serve() async {
    HttpServer server;

    var port = _settingsManager.settings.port;
    var localhost = "127.0.0.1";
    try {
      server = await shelf_io.serve(handleRequest, localhost, port);
    } on SocketException catch (err) {
      log.info("serve at http://$localhost:$port failed: $err");
      log.info("try to serve with a random port");
      server = await shelf_io.serve(handleRequest, localhost, 0);
      _settingsManager.settings.port = server.port;
      _settingsManager.save();
    }

    log.info("serving at http://$localhost:$port");
  }

  Future<Response> handleRequest(Request request) async {
    final urlString = request.url.toString();
    log.info("recived request ${request.requestedUri}");
    if (urlString.startsWith(getCharactersUrlPrefix)) {
      return handleGetCharacters(request);
    } else if (urlString.startsWith(viewProfileUrlPrefix)) {
      return handleViewProfile(request);
    } else if (urlString.startsWith(getPassiveSkillsUrlPrefix)) {
      return handleGetPassiveSkills(request);
    } else if (urlString.startsWith(getItemsUrlPrefix)) {
      return handleGetItems(request);
    }

    return Response.notFound("");
  }

  Future<Response> handleGetCharacters(Request request) async {
    var params = request.url.queryParameters;
    var accountName = params["accountName"];
    var realm = params["realm"];

    if (accountName == null || realm == null) {
      return Response.badRequest();
    }

    String data;
    try {
      data = await _requester.getCharacters(accountName, realm);
    } on HttpRequestException catch (err) {
      return Response(err.statusCode);
    }

    List<dynamic> list = jsonDecode(data);
    List<Character> characters =
        list.map((e) => Character.fromJson(e)).toList();
    for (var c in characters) {
      c.league = betterLeagueName(c.league);
    }
    return Response.ok(jsonEncode(characters),
        headers: {"content-type": "application/json"});
  }

  Future<Response> handleViewProfile(Request request) async {
    var accountName = request.url.pathSegments.last;

    if (accountName == "") {
      return Response.badRequest();
    }
    try {
      String data = await _requester.viewProfile(accountName);
      return Response.ok(data,
          headers: {"content-type": "text/html; charset=UTF-8"});
    } on HttpRequestException catch (err) {
      return Response(err.statusCode);
    }
  }

  Future<Response> handleGetPassiveSkills(Request request) async {
    var params = request.url.queryParameters;
    var accountName = params["accountName"];
    var character = params.containsKey("character")
        ? decodePobRequestUriComponent(params["character"]!)
        : null;
    var realm = params["realm"];
    if (accountName == null || character == null || realm == null) {
      return Response.badRequest();
    }

    try {
      String data =
          await _requester.getPassiveSkills(accountName, character, realm);
      return Response.ok(data, headers: {"content-type": "application/json"});
    } on HttpRequestException catch (err) {
      return Response(err.statusCode);
    }
  }

  Future<Response> handleGetItems(Request request) async {
    var params = request.url.queryParameters;
    var accountName = params["accountName"];
    var character = params.containsKey("character")
        ? decodePobRequestUriComponent(params["character"]!)
        : null;
    var realm = params["realm"];
    if (accountName == null || character == null || realm == null) {
      return Response.badRequest();
    }

    try {
      String data = await _requester.getItems(accountName, character, realm);
      return Response.ok(data, headers: {"content-type": "application/json"});
    } on HttpRequestException catch (err) {
      return Response(err.statusCode);
    }
  }

  void dealCharacters(List<Character> characters) {}

  String betterLeagueName(String league) {
    //Performance is bad, but not an issue here
    return league
        .replaceFirst("永久", "Standard")
        .replaceFirst("虚空", "Void")
        .replaceFirst("赛季", "")
        .replaceFirst("独狼", "SSF_")
        .replaceFirst("专家", "HC_")
        .replaceFirst("无情", "R_")
        .replaceFirst("（", "(")
        .replaceFirst("）", ")");
  }

  /// POB sends non-ASCII character name(commonly encoded by UTF-8) without uri encoding.
  /// UTF-16 based langauge's http server(like dart,javascript) receives original bytes as extends-ASCII chars
  /// and converts extends-ASCII chars to Unicode chars.
  ///
  /// So this method decodes out non-ASCII char by cuting off int16 to byte and decoding using UTF-8.
  decodePobRequestUriComponent(String component) {
    var buffer = Uint8List(component.length);
    for (var i = 0; i < component.length; i++) {
      buffer[i] = 0xFF & component.codeUnitAt(i);
    }
    return utf8.decode(buffer, allowMalformed: false);
  }
}

void main() async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  var settingsManager = SettingsManager();
  await settingsManager.load();
  var gateway =
      Gateway(Requester(settingsManager.settings.poeSessId), settingsManager);
  await gateway.serve();
}
