import 'package:flutter/services.dart';

/// Controller for managing OMID sessions.
class OmidSessionController {
  OmidSessionController._();

  static const _channel = MethodChannel('kontext_omid');

  /// Starts an OMID session.
  static Future<void> startSession({
    required String instanceId,
    required String partnerName,
    required String partnerVersion,
    String? contentUrl,
    String? customReferenceData,
  }) async {
    return _invoke('startOmidSession', {
      'instanceId': instanceId,
      'partnerName': partnerName,
      'partnerVersion': partnerVersion,
      'contentUrl': contentUrl,
      'customReferenceData': customReferenceData,
    });
  }

  /// Stops and cleans an OMID session.
  static Future<void> stopSession(String instanceId) async {
    return _invoke('stopOmidSession', {'instanceId': instanceId});
  }

  static Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      final foo = await _channel.invokeMethod(method, args);
      print('OMID method $method invoked with result: $foo');
    } on MissingPluginException catch (e) {
      throw PlatformException(code: 'missing_plugin', message: e.message);
    }
  }
}
