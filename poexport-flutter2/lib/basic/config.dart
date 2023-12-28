import 'dart:convert';
import 'dart:io';

import 'package:cn_poe_export/basic/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

const configFileName = 'config.json';

/// The application config.
class Config {
  var poeSessId = "";
  var pobPath = "";
  var listeningPort = 8655;
  var pobProxySupported = false;
  var exportMode = 0; //0: simple;1: expert

  Config();

  factory Config.fromJson(Map<String, dynamic> json) {
    var config = Config();
    if (json.containsKey("poeSessId")) {
      config.poeSessId = json['poeSessId'];
    }
    if (json.containsKey("pobPath")) {
      config.pobPath = json['pobPath'];
    }
    if (json.containsKey("listeningPort")) {
      config.listeningPort = json['listeningPort'];
    }
    if (json.containsKey("pobProxySupported")) {
      config.pobProxySupported = json['pobProxySupported'];
    }
    if (json.containsKey("exportMode")) {
      config.exportMode = json['exportMode'];
    }

    return config;
  }

  Map<String, dynamic> toJson() {
    return {
      "poeSessId": poeSessId,
      "pobPath": pobPath,
      "listeningPort": listeningPort,
      "pobProxySupported": pobProxySupported,
      "exportMode": exportMode,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Global single instance of ConfigManager.
///
/// Init it by calling configManager.load().
final configManager = ConfigManager();

/// ConfigManager is used to load or save config.
///
/// User should call load() to init config.
///
/// User should call save() to write config to disk if the settings is changed finally.
class ConfigManager {
  late Config config; //init by load()
  late File _configFile; //init by load()

  /// Load settings from application data floor.
  Future<void> load() async {
    var directory = await getApplicationDocumentsDirectory();
    _configFile = File(join(directory.path, appName, configFileName));
    if (await _configFile.exists()) {
      var jsonString = await _configFile.readAsString();
      Map<String, dynamic> json = jsonDecode(jsonString);
      config = Config.fromJson(json);
    } else {
      config = Config();
      save();
    }
  }

  /// Save settings to disk.
  Future<void> save() async {
    var json = config.toJson();
    const encoder = JsonEncoder.withIndent("  ");
    await _configFile.writeAsString(encoder.convert(json));
  }
}
