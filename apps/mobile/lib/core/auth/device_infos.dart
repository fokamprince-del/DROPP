import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final deviceInfosServiceProvider = Provider<DeviceInfosService>((ref) => DeviceInfosService(const FlutterSecureStorage()));

class DeviceInfos {
  final String model;
  final String id;

  DeviceInfos({required this.model, required this.id});

  Map<String, dynamic> toJson() => {'model': model, 'id': id};

  factory DeviceInfos.fromJson(Map<String, dynamic> json) =>
      DeviceInfos(model: json['model'] as String, id: json['id'] as String);
}

class DeviceInfosService {
  final FlutterSecureStorage _storage ;
  static const _cle = 'dropp.device';
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  DeviceInfosService(this._storage);

  Future<void> _ecrire(Map<String, dynamic> deviceInfos) async {
    final json = jsonEncode(deviceInfos);
    await _storage.write(key: _cle, value: json);
  }

  Future<Map<String, dynamic>?> _lire() async {
    final json = await _storage.read(key: _cle);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _effacer() async {
    await _storage.delete(key: _cle);
  }

  Future<String?> _readInfos() async {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.name;
      case TargetPlatform.iOS:
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.utsname.machine;
      default:
        return null;
    }
  }

  Future<DeviceInfos?> get() async {
    await _effacer();
    final infos = await _lire();
    if (infos != null) {
      return DeviceInfos.fromJson(infos);
    }
    final newModel = await _readInfos();
    if (newModel != null) {
      final newInfos = {'model': newModel, 'id': Uuid().v4()};
      await _ecrire(newInfos);
      return DeviceInfos.fromJson(newInfos);
    }
    return null;
  }
}
